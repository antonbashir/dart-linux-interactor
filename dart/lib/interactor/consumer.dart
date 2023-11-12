import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';

class NativeConsumerExecutor {
  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;
  final List<NativeCallbackExecutor> _callbacks;

  NativeConsumerExecutor(this._id, this._interactorPointer, this._bindings, this._buffers, this._callbacks);

  void call(Pointer<interactor_message_t> message) => _callbacks[message.ref.method].call(message);
}

class NativeCallbackExecutor {
  final int _id;
  final void Function(Pointer<interactor_message_t> message) _executor;

  NativeCallbackExecutor(this._id, this._executor);

  void call(Pointer<interactor_message_t> message) => _executor(message);
}
