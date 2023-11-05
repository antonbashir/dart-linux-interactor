import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';

class NativeProducerExecutor {
  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;
  final Map<Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>>, NativeMethodExecutor> _methods = {};

  NativeProducerExecutor(this._id, this._interactorPointer, this._bindings, this._buffers);

  NativeMethodExecutor register(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) {
    _methods[pointer] = NativeMethodExecutor(_id, _interactorPointer, _bindings, _buffers);
    return _methods[pointer]!;
  }
}

class NativeMethodExecutor {
  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  NativeMethodExecutor(this._id, this._interactorPointer, this._bindings, this._buffers);

  void call(int target) {
    final message = _bindings.interactor_dart_allocate_message(_interactorPointer);
    message.ref.method = _id;
    _bindings.interactor_dart_call_native(_interactorPointer, target, message);
  }
}
