import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';

class InteractorMessage {
  Pointer<interactor_message> _message;
  final Pointer<interactor_dart> _interactor;
  final InteractorBindings _bindings;
  final Completer<InteractorMessage> _completer;

  InteractorMessage(this._interactor, this._message, this._bindings, this._completer);

  void callback(Pointer<interactor_message> message) {
    _message = message;
    _completer.complete(this);
  }

  void free() => _bindings.interactor_dart_free_message(_interactor, _message);
}
