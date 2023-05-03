import 'dart:developer' as dev;

class Logger {
  Logger(this.type);

  final Type type;
  bool _enabled = true;

  void disableLogs() {
    _enabled = false;
  }

  void log(Object? message) {
    if (_enabled) dev.log("$type: $message");
  }
}
