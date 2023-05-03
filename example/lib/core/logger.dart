import 'dart:developer' as dev;

class Logger {
  Logger(this.type);

  final Type type;

  void log(Object? message) {
    dev.log("$type: $message");
  }
}
