import 'package:get/get_navigation/src/root/internacionalization.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': enUS,
    'hi': hiIN,
    'es': esES,
  };
  final Map<String, String> enUS = {
    "title_recorder": "MediNote Recorder",

    "lang_en": "English",
    "lang_hi": "Hindi",
    "lang_es": "Spanish",

    "theme_light": "Light",
    "theme_dark": "Dark",
    "theme_system": "System",

    "status_recording": "Recording… (background allowed)",
    "status_ready": "Ready to record",

    "btn_start": "Start",
    "btn_stop": "Stop",

    "pending_uploads": "Pending uploads: @count",
    "saved_path": "Saved: @path",
  };

  final Map<String, String> hiIN = {
    "title_recorder": "मेडीनोट रिकॉर्डर",

    "lang_en": "अंग्रेज़ी",
    "lang_hi": "हिन्दी",
    "lang_es": "स्पेनिश",

    "theme_light": "लाइट",
    "theme_dark": "डार्क",
    "theme_system": "सिस्टम",

    "status_recording": "रिकॉर्डिंग… (पृष्ठभूमि अनुमति)",
    "status_ready": "रिकॉर्डिंग के लिए तैयार",

    "btn_start": "शुरू करें",
    "btn_stop": "रोकें",

    "pending_uploads": "लंबित अपलोड: @count",
    "saved_path": "सेव किया गया: @path",
  };

  final Map<String, String> esES = {
    "title_recorder": "Grabadora MediNote",

    "lang_en": "Inglés",
    "lang_hi": "Hindi",
    "lang_es": "Español",

    "theme_light": "Claro",
    "theme_dark": "Oscuro",
    "theme_system": "Sistema",

    "status_recording": "Grabando… (permitido en segundo plano)",
    "status_ready": "Listo para grabar",

    "btn_start": "Iniciar",
    "btn_stop": "Detener",

    "pending_uploads": "Cargas pendientes: @count",
    "saved_path": "Guardado: @path",
  };

}
