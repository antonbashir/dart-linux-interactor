import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';
import 'exception.dart';

class InteractorPayloads {
  final Map<int, Pointer<interactor_payload_pool>> _pools = {};

  final Pointer<interactor_dart_t> _interactor;

  InteractorPayloads(this._interactor);

  InteractorPayloadPool<T> register<T extends Struct>(int size) {
    final pool = interactor_dart_payload_pool_create(_interactor, size);
    _pools[T.hashCode] = pool;
    return InteractorPayloadPool<T>(pool);
  }

  @pragma(preferInlinePragma)
  int size<T extends Struct>() => _pools[T.hashCode]?.ref.size ?? 0;

  @pragma(preferInlinePragma)
  Pointer<T> allocate<T extends Struct>() {
    final pool = _pools[T.hashCode];
    if (pool == null) throw InteractorRuntimeException(InteractorErrors.interactorMemoryError);
    return Pointer.fromAddress(interactor_dart_payload_allocate(pool));
  }

  @pragma(preferInlinePragma)
  void free<T extends Struct>(Pointer<T> payload) {
    final pool = _pools[T.hashCode];
    if (pool == null) return;
    interactor_dart_payload_free(pool, payload.address);
  }

  @pragma(preferInlinePragma)
  void destroy() {
    _pools.values.forEach((pool) => interactor_dart_payload_pool_destroy(pool));
    _pools.clear();
  }
}

class InteractorPayloadPool<T extends Struct> {
  final Pointer<interactor_payload_pool> _pool;

  InteractorPayloadPool(this._pool);

  @pragma(preferInlinePragma)
  int size() => _pool.ref.size;

  @pragma(preferInlinePragma)
  Pointer<T> allocate() => Pointer.fromAddress(interactor_dart_payload_allocate(_pool));

  @pragma(preferInlinePragma)
  void free(Pointer<T> payload) => interactor_dart_payload_free(_pool, payload.address);
}
