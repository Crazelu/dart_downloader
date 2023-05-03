import 'package:flutter/material.dart';

class CancelOrPauseToken {
  late final ValueNotifier<Event> _notifier;

  CancelOrPauseToken() {
    _notifier = ValueNotifier(Event.none);
  }

  ValueNotifier<Event> get eventNotifier => _notifier;

  void cancel() {
    _notifier.value = Event.cancel;
  }

  void pause() {
    _notifier.value = Event.pause;
  }

  void resume() {
    _notifier.value = Event.none;
  }

  void dispose() {
    _notifier.dispose();
  }
}

enum Event { cancel, pause, none }
