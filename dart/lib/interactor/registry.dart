import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'constants.dart';
import 'consumer.dart';
import 'data.dart';
import 'declaration.dart';
import 'payloads.dart';
import 'producer.dart';

class InteractorConsumerRegistry {
  final _consumers = <NativeConsumerExecutor>[];

  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;

  InteractorConsumerRegistry(
    this._interactor,
    this._bindings,
  );

  void register(InteractorConsumer declaration) {
    final callbacks = <NativeCallbackExecutor>[];
    for (var callback in declaration.callbacks()) {
      callbacks.add(NativeCallbackExecutor(_bindings, _interactor, callback.callback));
    }
    _consumers.add(NativeConsumerExecutor(callbacks));
  }

  @pragma(preferInlinePragma)
  void call(Pointer<interactor_message_t> message) => _consumers[message.ref.owner].call(message);
}

class InteractorProducerRegistry {
  final _producers = <NativeProducerExecutor>[];

  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;
  final InteractorDatas _datas;

  InteractorProducerRegistry(
    this._interactor,
    this._bindings,
    this._payloads,
    this._buffers,
    this._datas,
  );

  T register<T extends InteractorProducer>(T provider) {
    final id = _producers.length;
    final executor = NativeProducerExecutor(id, _interactor, _bindings, _payloads, _buffers, _datas);
    _producers.add(executor);
    return provider..initialize(executor);
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _producers[message.ref.owner].callback(message);
}
