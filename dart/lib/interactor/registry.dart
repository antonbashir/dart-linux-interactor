import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';
import 'consumer.dart';
import 'declaration.dart';
import 'producer.dart';

class InteractorConsumerRegistry {
  final _consumers = <InteractorConsumerExecutor>[];

  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;

  InteractorConsumerRegistry(
    this._interactor,
    this._bindings,
  );

  void register(InteractorConsumer declaration) {
    final callbacks = <InteractorCallbackExecutor>[];
    for (var callback in declaration.callbacks()) {
      callbacks.add(InteractorCallbackExecutor(_bindings, _interactor, callback));
    }
    _consumers.add(InteractorConsumerExecutor(callbacks));
  }

  @pragma(preferInlinePragma)
  void call(Pointer<interactor_message_t> message) => _consumers[message.ref.owner].call(message);
}

class InteractorProducerRegistry {
  final _producers = <InteractorProducerExecutor>[];

  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;

  InteractorProducerRegistry(
    this._interactor,
    this._bindings,
  );

  T register<T extends InteractorProducer>(T provider) {
    final id = _producers.length;
    final executor = InteractorProducerExecutor(id, _interactor, _bindings);
    _producers.add(executor);
    return provider..initialize(executor);
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _producers[message.ref.owner].callback(message);
}
