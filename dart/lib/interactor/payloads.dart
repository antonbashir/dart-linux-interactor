import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';
import 'exception.dart';

class InteractorPayloads {
  final Map<int, Pointer<interactor_payload_pool>> _pools = {};

  final Pointer<interactor_dart> _interactor;

  InteractorPayloads(this._interactor);

  InteractorPayloadPool<T> register<T extends Struct>(int size) {
    final pool = interactor_dart_payload_pool_create(_interactor, size);
    _pools[T.hashCode] = pool;
    return InteractorPayloadPool<T>(pool);
  }

  @pragma(preferInlinePragma)
  int size<T extends Struct>() => interactor_dart_payload_pool_size(_pools[T.hashCode]!.cast());

  @pragma(preferInlinePragma)
  Pointer<T> allocate<T extends Struct>() {
    final pool = _pools[T.hashCode];
    if (pool == null) throw InteractorRuntimeException(InteractorErrors.interactorMemoryError);
    return interactor_dart_payload_allocate(pool).cast();
  }

  @pragma(preferInlinePragma)
  void free<T extends Struct>(Pointer<T> payload) {
    final pool = _pools[T.hashCode];
    if (pool == null) return;
    interactor_dart_payload_free(pool, payload.cast());
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
  int size() => interactor_dart_payload_pool_size(_pool);

  @pragma(preferInlinePragma)
  Pointer<T> allocate() => interactor_dart_payload_allocate(_pool).cast();

  @pragma(preferInlinePragma)
  void free(Pointer<T> payload) => interactor_dart_payload_free(_pool, payload.cast());
}
