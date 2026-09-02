import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class LoggerService {
  static void log(String message, {String name = 'CatPoeApp', Object? error}) {
    developer.log(message, name: name, error: error);
  }

  static void info(String message) {
    if (kReleaseMode) return;
    log(message, name: 'INFO');
  }

  static void warning(String message) {
    if (kReleaseMode) return;
    log(message, name: 'WARNING');
  }

  static void error(String message, [Object? error]) {
    log(message, name: 'ERROR', error: error);
  }
}


