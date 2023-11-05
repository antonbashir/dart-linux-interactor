import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'declaration.dart';
import 'producer.dart';

class InteractorProducerFactory {
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  InteractorProducerFactory(
    this._interactorPointer,
    this._bindings,
    this._buffers,
  );

  final _producer = <NativeProducerExecutor>[];

  T register<T extends NativeProducer>(T provider) {
    final executor = NativeProducerExecutor(
      _producer.length,
      _interactorPointer,
      _bindings,
      _buffers,
    );
    return provider..initialize(executor);
  }
}
