import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'operation.dart';

class NativeService {
  final int _id;
  final Pointer<interactor_dart_t> _workerPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;
  final List<NativeFunction> _functions;

  NativeService(this._id, this._workerPointer, this._bindings, this._buffers, this._functions);

  void execute(Pointer<interactor_message_t> message) => _functions[message.ref.operation_id].execute(message);
}
