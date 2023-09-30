import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';

class NativeProducer {
  final int _id;
  final Pointer<interactor_dart_t> _workerPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;
  final Map<Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>>, NativeMethod> _methods;

  NativeProducer(this._id, this._workerPointer, this._bindings, this._buffers, this._methods);

  NativeMethod of(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) => _methods[pointer]!;
}

class NativeMethod {
  final int _id;
  final Pointer<interactor_dart_t> _workerPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  NativeMethod(this._id, this._workerPointer, this._bindings, this._buffers);

  void execute(int target, Pointer<interactor_message_t> message) {
    _bindings.interactor_dart_send(_workerPointer.ref.ring.cast(), target, message);
  }
}
