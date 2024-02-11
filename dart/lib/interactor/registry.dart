import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';
import 'consumer.dart';
import 'declaration.dart';
import 'producer.dart';

class InteractorConsumerRegistry {
  final _consumers = <InteractorConsumerExecutor>[];

  final Pointer<interactor_dart> _interactor;

  InteractorConsumerRegistry(this._interactor);

  void register(InteractorConsumer declaration) {
    final callbacks = <InteractorCallbackExecutor>[];
    for (var callback in declaration.callbacks()) {
      callbacks.add(InteractorCallbackExecutor(_interactor, callback));
    }
    _consumers.add(InteractorConsumerExecutor(callbacks));
  }

  @pragma(preferInlinePragma)
  void call(Pointer<interactor_message> message) => _consumers[message.ref.owner].call(message);
}

class InteractorProducerRegistry {
  final _producers = <InteractorProducerExecutor>[];

  final Pointer<interactor_dart> _interactor;

  InteractorProducerRegistry(this._interactor);

  T register<T extends InteractorProducer>(T provider) {
    final id = _producers.length;
    final executor = InteractorProducerExecutor(id, _interactor);
    _producers.add(executor);
    return provider..initialize(executor);
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message> message) => _producers[message.ref.owner].callback(message);
}
