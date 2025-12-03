





































































































import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/page/record.dart';
import 'package:untitled/settingsController.dart';
import 'package:untitled/translation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await GetStorage.init();
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  final SettingsController settings = Get.put(SettingsController());
   MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(()=>GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: Locale('en'),
      fallbackLocale: Locale('en'),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: settings.themeMode.value,
      home: RecordingPage(),
    ));
  }
}
