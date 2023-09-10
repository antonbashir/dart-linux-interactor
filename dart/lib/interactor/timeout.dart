import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';

class InteractorTimeoutChecker {
  final InteractorBindings _bindings;
  final Pointer<interactor_dart_t> _workerPointer;
  final Duration _period;

  late final Timer _timer;

  InteractorTimeoutChecker(this._bindings, this._workerPointer, this._period);

  void start() => _timer = Timer.periodic(_period, _check);

  void stop() => _timer.cancel();

  void _check(Timer timer) {
    if (timer.isActive) _bindings.interactor_dart_check_event_timeouts(_workerPointer);
  }
}
