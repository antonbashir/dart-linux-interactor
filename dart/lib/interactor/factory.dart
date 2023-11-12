import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'declaration.dart';
import 'payloads.dart';
import 'producer.dart';

class InteractorProducerFactory {
  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;

  InteractorProducerFactory(
    this._interactor,
    this._bindings,
    this._payloads,
    this._buffers,
  );

  final _producers = <NativeProducerExecutor>[];

  T register<T extends NativeProducer>(T provider) {
    final id = _producers.length;
    final executor = NativeProducerExecutor(id, _interactor, _bindings, _payloads, _buffers);
    _producers.add(executor);
    return provider..initialize(executor);
  }

  void callback(Pointer<interactor_message_t> message) => _producers[message.ref.owner].callback(message);
}
