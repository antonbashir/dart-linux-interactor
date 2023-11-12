import 'dart:ffi';

import 'bindings.dart';
import 'declaration.dart';
import 'producer.dart';

class InteractorProducerFactory {
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;

  InteractorProducerFactory(
    this._interactorPointer,
    this._bindings,
  );

  final _producers = <NativeProducerExecutor>[];

  T register<T extends NativeProducer>(T provider) {
    final id = _producers.length;
    final executor = NativeProducerExecutor(
      id,
      _interactorPointer,
      _bindings,
    );
    _producers.add(executor);
    return provider..initialize(executor);
  }

  void callback(Pointer<interactor_message_t> message) => _producers[message.ref.owner].callback(message);
}
