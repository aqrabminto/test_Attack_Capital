
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../model/session.dart';
import '../service/apiSer.dart';
import '../service/upload.dart';

class RecordingController extends GetxController {
  
  final AudioRecorder recorder = AudioRecorder();
  RxBool isRecording = false.obs;
  RxString savedPath = "".obs;
  RxInt pendingUploads = 0.obs;

  
  String? filePath;
  int lastBytesSent = 0;
  int chunkCounter = 0;

  
  final RxList uploadQueue = [].obs;

  
  Timer? chunkTimer;
  bool _processingQueue = false;

  
  RecordingSession? session;

  
  final GetStorage _box = GetStorage();

  
  StreamSubscription<ConnectivityResult>? connectivitySub;

  
  static const String _kQueueKey = 'record_upload_queue';
  static const String _kNextChunkCounter = 'record_next_chunk_counter';
  static const String _kLastBytesSent = 'record_last_bytes_sent';
  static const String _kSessionId = 'record_session_id';
  static const String _kFilePath = 'record_file_path';

  @override
  void onInit() {
    super.onInit();

    
    ApiService.login().catchError((e) {
          });

    
    _loadQueueFromDisk();


    
   StreamSubscription? connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final connected = result != ConnectivityResult.none;
      if (connected) {
                _processQueue();
      }
    });

    
    final sid = _box.read<String?>(_kSessionId);
    if (sid != null && sid.isNotEmpty) {
      session = RecordingSession(sid);
    }
    filePath = _box.read<String?>(_kFilePath);
    lastBytesSent = _box.read<int?>(_kLastBytesSent) ?? 0;
    chunkCounter = _box.read<int?>(_kNextChunkCounter) ?? 0;
    pendingUploads.value = uploadQueue.length;
  }

  @override
  void onClose() {
    connectivitySub?.cancel();
    chunkTimer?.cancel();
    _ampSub?.cancel();
    recorder.dispose();
    super.onClose();
  }

  
  
  
  Future<void> startRecording() async {
    
    if (!await Permission.microphone.request().isGranted) {
      Get.snackbar("Permission", "Microphone permission denied");
      return;
    }

    if (!await recorder.hasPermission()) {
      Get.snackbar("Permission", "Record package permission denied");
      return;
    }

    
    late final String sessionId;
    try {
      sessionId = await ApiService.createSession(patientId: "patient_123");
    } catch (e) {
      Get.snackbar("Unable to connect Network", "Failed to create session",backgroundColor: Colors.red,icon: Icon(Icons.network_check),);
      return;
    }
    session = RecordingSession(sessionId);
    _box.write(_kSessionId, sessionId);

    
    final dir = await getTemporaryDirectory();
    filePath = p.join(dir.path, "rec_${DateTime.now().millisecondsSinceEpoch}.wav");
        _box.write(_kFilePath, filePath);

    
    lastBytesSent = 0;
    chunkCounter = 0;
    uploadQueue.clear();
    pendingUploads.value = 0;
    _saveQueueToDisk();

    try {
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,

        ),
        path: filePath!,
      );
      await _startAmplitudeStream();
    } catch (e) {
      Get.snackbar("Error", "Failed to start recorder: $e");
      return;
    }

    isRecording.value = true;

    
    chunkTimer?.cancel();
    chunkTimer = Timer.periodic(const Duration(seconds: 1), (_) => _readNewBytesAndQueue());
  }

  Future<void> stopRecording() async {
    
    
    String? saved;
    try {
      saved = await recorder.stop();
      _stopAmplitudeStream();
    } catch (e) {
          }
    isRecording.value = false;

    
    await _readNewBytesAndQueue();

    
    final maxWait = Duration(seconds: 10);
    final stopwatch = Stopwatch()..start();
    while ((uploadQueue.isNotEmpty || _processingQueue) && stopwatch.elapsed < maxWait) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    stopwatch.stop();

    
    final lastChunkNumber = chunkCounter; 
    try {
      await ApiService.notifyChunk(
        sessionId: session!.sessionId,
        chunk: lastChunkNumber,
        gcsPath: _box.read("gcsPath"),
        publicUrl: "",
        isLast: true,
      );
    } catch (e) {
            
    }

    
    savedPath.value = saved ?? filePath ?? "";
    chunkTimer?.cancel();
    _box.remove(_kFilePath);
    _box.remove(_kLastBytesSent);
  }

  
  
  
  Future<void> _readNewBytesAndQueue() async {
    final localPath = filePath;
    if (localPath == null) return;
    final f = File(localPath);

    if (!await f.exists()) return;

    final length = await f.length();

    if (length <= lastBytesSent) {
      
      return;
    }

    
    final int delta = (length - lastBytesSent).toInt();
    if (delta < 512 && isRecording.value) {
      
      return;
    }

    
    await Future.delayed(const Duration(milliseconds: 100));

    RandomAccessFile raf = await f.open();
    try {
      raf.setPositionSync(lastBytesSent);
      final int toRead = (length - lastBytesSent).toInt();
      final List<int> newBytes = raf.readSync(toRead);
      if (newBytes.isEmpty) return;

      final Uint8List payload = Uint8List.fromList(newBytes);

      
      _enqueueChunk(payload);
      
      lastBytesSent = length;
      _box.write(_kLastBytesSent, lastBytesSent);
    } finally {
      await raf.close();
    }

    
    _processQueue();
  }

  void _enqueueChunk(Uint8List payload) {
    uploadQueue.add({
      'index': chunkCounter++,
      'bytes': payload,
    });
    pendingUploads.value = uploadQueue.length;

    
    _saveQueueToDisk();
    _box.write(_kNextChunkCounter, chunkCounter);
  }

  
  
  
  void _saveQueueToDisk() {
    final serial = uploadQueue.map((e) {
      return {
        'index': e['index'],
        
        'bytes': base64Encode(e['bytes'] as Uint8List),
      };
    }).toList();
    _box.write(_kQueueKey, serial);
    _box.write(_kNextChunkCounter, chunkCounter);
  }

  void _loadQueueFromDisk() {
    final List<dynamic>? stored = _box.read<List<dynamic>>(_kQueueKey);
    uploadQueue.clear();
    if (stored != null) {
      for (final item in stored) {
        try {
          final int idx = item['index'] as int;
          final String b64 = item['bytes'] as String;
          final Uint8List bytes = base64Decode(b64);
          uploadQueue.add({'index': idx, 'bytes': bytes});
        } catch (e) {
          
                  }
      }
    }
    chunkCounter = _box.read<int?>(_kNextChunkCounter) ?? chunkCounter;
    pendingUploads.value = uploadQueue.length;
  }

  
  
  
  Future<void> _processQueue() async {
    if (_processingQueue || uploadQueue.isEmpty) return;
    _processingQueue = true;

    
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
            _processingQueue = false;
      return;
    }

    while (uploadQueue.isNotEmpty) {
      final item = uploadQueue.first;
      final int idx = item['index'] as int;
      final Uint8List bytes = item['bytes'] as Uint8List;

      
      final connectivityNow = await Connectivity().checkConnectivity();
      if (connectivityNow == ConnectivityResult.none) {
                break;
      }

      try {
        
        final presigned = await ApiService.getPresignedUrl(
          sessionId: session!.sessionId,
          chunkNumber: idx,
        );
_box.write("gcsPath", presigned["gcsPath"]);
        
        bool ok = false;
        int attempt = 0;
        int delaySec = 2;
        while (!ok) {
          attempt += 1;
          ok = await UploadService.uploadToPresignedUrl(
            url: presigned['url'],
            bytes: bytes,
          );

          if (ok) break;

          
          final conn = await Connectivity().checkConnectivity();
          if (conn == ConnectivityResult.none) {
                        break;
          }

          
          await Future.delayed(Duration(seconds: delaySec));
          delaySec = (delaySec * 2).clamp(2, 60);
          
          if (attempt >= 6) {
                        break;
          }
        }

        if (!ok) {
          
                    break;
        }

        
        await ApiService.notifyChunk(
          sessionId: session!.sessionId,
          chunk: idx,
          gcsPath: presigned['gcsPath'],
          publicUrl: presigned['publicUrl'],
          isLast: false,
        );

        
        uploadQueue.removeAt(0);
        pendingUploads.value = uploadQueue.length;
        _saveQueueToDisk();
      } catch (e) {
                
        await Future.delayed(const Duration(seconds: 2));
        break;
      }
    }

    _processingQueue = false;
  }

  RxDouble currentDb = 0.0.obs;
  StreamSubscription<Amplitude>? _ampSub;

  Future<void> _startAmplitudeStream() async {
    _ampSub?.cancel();
    _ampSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amp) {
      
      currentDb.value = amp.current.toDouble();
    });
  }

  void _stopAmplitudeStream() {
    _ampSub?.cancel();
    _ampSub = null;
  }
}
