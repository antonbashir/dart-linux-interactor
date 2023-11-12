import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';

class InteractorCall {
  Pointer<interactor_message> _message;
  final Pointer<interactor_dart> _interactor;
  final InteractorBindings _bindings;
  final Completer<InteractorCall> _completer;

  InteractorCall(this._interactor, this._message, this._bindings, this._completer);

  void setBool(bool data) {
    _message.ref.input = Pointer.fromAddress(data ? 1 : 0);
  }

  bool getBool() => _message.ref.output.value == 1;

  void callback(Pointer<interactor_message> message) {
    _message = message;
    _completer.complete(this);
  }

  void free() => _bindings.interactor_dart_free_message(_interactor, _message);
}

class InteractorNotification {
  Pointer<interactor_message> _message;
  final Pointer<interactor_dart> _interactor;
  final InteractorBindings _bindings;

  InteractorNotification(this._interactor, this._message, this._bindings);

  void free() => _bindings.interactor_dart_free_message(_interactor, _message);
}
