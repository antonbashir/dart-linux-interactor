import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'declaration.dart';
import 'producer.dart';

class InteractorProducerFactory {
  final Pointer<interactor_dart_t> _workerPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  InteractorProducerFactory(
    this._workerPointer,
    this._bindings,
    this._buffers,
  );

  final _producer = <NativeProducer>[];

  T register<T extends NativeProducerProvider>(T provider) {
    final methods = <Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>>, NativeMethod>{};
    for (var method in provider.methods()) {
      methods[method.method] = NativeMethod(methods.length, _workerPointer, _bindings, _buffers);
    }
    final producer = NativeProducer(
      _producer.length,
      _workerPointer,
      _bindings,
      _buffers,
      methods,
    );
    provider.initialize(producer);
    return provider;
  }
}
