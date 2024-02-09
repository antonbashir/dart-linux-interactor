import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'bindings.dart';
import 'constants.dart';

class InteractorBuffers {
  final Pointer<iovec> buffers;
  final Queue<Completer<void>> _finalizers = Queue();
  final Pointer<interactor_dart_t> _worker;

  late final int bufferSize;
  late final int buffersCount;

  InteractorBuffers(this.buffers, this._worker) {
    bufferSize = _worker.ref.buffer_size;
    buffersCount = _worker.ref.buffers_count;
  }

  @pragma(preferInlinePragma)
  void release(int bufferId) {
    interactor_dart_release_buffer(_worker, bufferId);
    if (_finalizers.isNotEmpty) _finalizers.removeLast().complete();
  }

  @pragma(preferInlinePragma)
  Uint8List read(int bufferId) {
    final buffer = buffers.elementAt(bufferId);
    final bufferBytes = buffer.ref.iov_base.cast<Uint8>();
    return bufferBytes.asTypedList(buffer.ref.iov_len);
  }

  @pragma(preferInlinePragma)
  void setLength(int bufferId, int length) => buffers.elementAt(bufferId).ref.iov_len = length;

  @pragma(preferInlinePragma)
  void write(int bufferId, Uint8List bytes) {
    final buffer = buffers.elementAt(bufferId);
    buffer.ref.iov_base.cast<Uint8>().asTypedList(bytes.length).setAll(0, bytes);
    buffer.ref.iov_len = bytes.length;
  }

  @pragma(preferInlinePragma)
  int? get() {
    final buffer = interactor_dart_get_buffer(_worker);
    if (buffer == interactorBufferUsed) return null;
    return buffer;
  }

  Future<int> allocate() async {
    var bufferId = interactor_dart_get_buffer(_worker);
    while (bufferId == interactorBufferUsed) {
      if (_finalizers.isNotEmpty) {
        await _finalizers.last.future;
        bufferId = interactor_dart_get_buffer(_worker);
        continue;
      }
      final completer = Completer();
      _finalizers.add(completer);
      await completer.future;
      bufferId = interactor_dart_get_buffer(_worker);
    }
    return bufferId;
  }

  Future<List<int>> allocateArray(int count) async {
    final bufferIds = <int>[];
    for (var index = 0; index < count; index++) bufferIds.add(get() ?? await allocate());
    return bufferIds;
  }

  @pragma(preferInlinePragma)
  int available() => interactor_dart_available_buffers(_worker);

  @pragma(preferInlinePragma)
  int used() => interactor_dart_used_buffers(_worker);

  @pragma(preferInlinePragma)
  void releaseArray(List<int> buffers) {
    for (var id in buffers) release(id);
  }
}
