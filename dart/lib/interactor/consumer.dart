import 'dart:ffi';

import 'bindings.dart';
import 'messages.dart';

class NativeConsumerExecutor {
  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final List<NativeCallbackExecutor> _callbacks;

  NativeConsumerExecutor(this._id, this._interactorPointer, this._bindings, this._callbacks);

  void call(Pointer<interactor_message_t> message) => _callbacks[message.ref.method].call(message);
}

class NativeCallbackExecutor {
  final int _id;
  final InteractorBindings _bindings;
  final Pointer<interactor_dart_t> _interactorPointer;
  final void Function(InteractorNotification notification) _executor;

  NativeCallbackExecutor(this._id, this._bindings, this._interactorPointer, this._executor);

  void call(Pointer<interactor_message_t> message) => _executor(InteractorNotification(_interactorPointer, message, _bindings));
}
