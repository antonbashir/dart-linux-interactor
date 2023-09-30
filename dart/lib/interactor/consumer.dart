import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';

class NativeConsumerExecutor {
  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;
  final List<NativeCallbackExecutor> _functions;

  NativeConsumerExecutor(this._id, this._interactorPointer, this._bindings, this._buffers, this._functions);

  void execute(Pointer<interactor_message_t> message) => _functions[message.ref.method_id].execute(message);
}

class NativeCallbackExecutor {
  final int _id;
  final void Function(Pointer<interactor_message_t> message) _executor;

  NativeCallbackExecutor(this._id, this._executor);

  void execute(Pointer<interactor_message_t> message) => _executor(message);
}
