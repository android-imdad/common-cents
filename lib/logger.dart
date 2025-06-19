import 'package:flutter/foundation.dart';

class Logger{

  static void debug({required String tag, required String text}) {
    if (kDebugMode) {
      debugPrint("RupiyalLogger $tag Debug : $text");
    }
  }

  static void error({required String tag, required String text}) {
    if (kDebugMode) {
      debugPrint("RupiyalLogger $tag Error : $text");
    }
  }

  static void info({required String tag, required String text}) {
    if (kDebugMode) {
      debugPrint("RupiyalLogger $tag Info : $text");
    }
  }
}