

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final box = GetStorage();
  final themeMode = Rx<ThemeMode>(ThemeMode.system);
  final locale = Rx<Locale>(Locale('en'));


  @override
  void onInit() {
    super.onInit();
    String? t = box.read('theme');
    String? l = box.read('locale');
    if (t != null) {
      themeMode.value = t == 'dark' ? ThemeMode.dark : (t == 'light' ? ThemeMode.light : ThemeMode.system);
    }
    if (l != null) {
      locale.value = Locale(l);
    }
  }


  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    box.write('theme', mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system'));
    Get.changeThemeMode(mode);
  }


  void setLocale(Locale newLocale) {
    // locale.value = newLocale;
    box.write('locale', newLocale.languageCode);
    Get.updateLocale(newLocale);
  }
}