
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/recController.dart';
import '../settingsController.dart';

class RecordingPage extends StatelessWidget {
  RecordingPage({super.key});

  final RecordingController controller = Get.put(RecordingController());
  final SettingsController settings = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("title_recorder".tr),
        actions: [
          PopupMenuButton<String>(
            onSelected: (s) {
              if (s == 'en') settings.setLocale(Locale('en'));
              if (s == 'hi') settings.setLocale(Locale('hi'));
              if (s == 'es') settings.setLocale(Locale('es'));
              if (s == 'dark') settings.setTheme(ThemeMode.dark);
              if (s == 'light') settings.setTheme(ThemeMode.light);
              if (s == 'system') settings.setTheme(ThemeMode.system);
            },
            itemBuilder: (c) => [
              PopupMenuItem(value: 'en', child: Text('lang_en'.tr)),
              PopupMenuItem(value: 'hi', child: Text('lang_hi'.tr)),
              PopupMenuItem(value: 'es', child: Text('lang_es'.tr)),
              PopupMenuDivider(),
              PopupMenuItem(value: 'light', child: Text('theme_light'.tr)),
              PopupMenuItem(value: 'dark', child: Text('theme_dark'.tr)),
              PopupMenuItem(value: 'system', child: Text('theme_system'.tr)),
            ],
          )
        ],
      ),
      body: SizedBox(
        child: Center(
          child: Obx(() => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.isRecording.value
                    ? "status_recording".tr
                    : "status_ready".tr,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (controller.isRecording.value) {
                    controller.stopRecording();
                  } else {
                    controller.startRecording();
                  }
                },
                child: Text(
                  controller.isRecording.value
                      ? "btn_stop".tr
                      : "btn_start".tr,
                ),
              ),
              const SizedBox(height: 20),
              Text("pending_uploads".trParams({
                "count": "${controller.uploadQueue.length}",
              })),
              const SizedBox(height: 8),
              audioLevelBar(controller.currentDb.value),
              if (controller.savedPath.value.isNotEmpty)
                Text(
                  "saved_path".trParams({
                    "path": controller.savedPath.value,
                  }),
                  textAlign: TextAlign.center,
                ),
            ],
          )),
        ),
      ),
    );
  }

  Widget audioLevelBar(double db) {
    final normalized = (db + 60) / 60;
    final barWidth = normalized * 200;

    return Container(
      height: 20,
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: 20,
        width: barWidth.clamp(0, 200),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
