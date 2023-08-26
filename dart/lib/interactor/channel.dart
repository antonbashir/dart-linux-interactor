import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';

class InteractorChannel {
  final Pointer<interactor_worker_t> _workerPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  const InteractorChannel(this._workerPointer, this._bindings, this._buffers);
}
