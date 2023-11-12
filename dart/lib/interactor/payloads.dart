import 'dart:ffi';

import 'bindings.dart';

class InteractorPayloads {
  final Map<int, Pointer<interactor_payloads_pool>> _pools = {};

  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;

  InteractorPayloads(this._bindings, this._interactor);

  int size<T extends Struct>() => _pools[T.hashCode]?.ref.size ?? 0;

  void register<T extends Struct>(int size) {
    _pools[T.hashCode] = _bindings.interactor_dart_payload_pool_create(_interactor, size);
  }

  Pointer<T> allocate<T extends Struct>() {
    final pool = _pools[T.hashCode];
    if (pool == null) return nullptr;
    return Pointer.fromAddress(_bindings.interactor_dart_payload_allocate(pool));
  }

  void free<T extends Struct>(Pointer<T> payload) {
    final pool = _pools[T.hashCode];
    if (pool == null) return;
    _bindings.interactor_dart_payload_free(pool, payload.address);
  }
}
