import 'dart:typed_data';

import 'buffers.dart';
import 'constants.dart';

class InteractorPayloadPool {
  final InteractorBuffers _buffers;
  final _payloads = <InteractorPayload>[];

  InteractorPayloadPool(int buffersCount, this._buffers) {
    for (var bufferId = 0; bufferId < buffersCount; bufferId++) {
      _payloads.add(InteractorPayload(bufferId, this));
    }
  }

  @pragma(preferInlinePragma)
  InteractorPayload getPayload(int bufferId, Uint8List bytes) {
    final payload = _payloads[bufferId];
    payload._bytes = bytes;
    return payload;
  }

  @pragma(preferInlinePragma)
  void release(int bufferId) => _buffers.release(bufferId);
}

class InteractorPayload {
  late Uint8List _bytes;
  final int _bufferId;
  final InteractorPayloadPool _pool;

  Uint8List get bytes => _bytes;

  InteractorPayload(this._bufferId, this._pool);

  @pragma(preferInlinePragma)
  void release() => _pool.release(_bufferId);

  @pragma(preferInlinePragma)
  Uint8List takeBytes({bool release = true}) {
    final result = Uint8List.fromList(bytes);
    if (release) this.release();
    return result;
  }

  @pragma(preferInlinePragma)
  List<int> toBytes({bool release = true}) {
    final result = _bytes.toList();
    if (release) this.release();
    return result;
  }
}
