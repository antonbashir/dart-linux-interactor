import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'constants.dart';

class InteractorChannel {
  final int fd;
  final Pointer<interactor_worker_t> _workerPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  const InteractorChannel(this._workerPointer, this.fd, this._bindings, this._buffers);

  
  @pragma(preferInlinePragma)
  void close() => _bindings.interactor_close_descritor(fd);
}
