import 'dart:ffi';

import 'buffers.dart';
import 'consumer.dart';
import 'declaration.dart';

import 'bindings.dart';
import 'producer.dart';

class InteractorConsumerRegistry {
  final Pointer<interactor_dart_t> _workerPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  InteractorConsumerRegistry(
    this._workerPointer,
    this._bindings,
    this._buffers,
  );

  final _consumers = <NativeConsumer>[];

  void register(NativeConsumerDeclaration declaration) {
    final callbacks = <NativeCallback>[];
    for (var callback in declaration.callbacks()) {
      callbacks.add(NativeCallback(callbacks.length, callback.callback));
    }
    _consumers.add(NativeConsumer(
      _consumers.length,
      _workerPointer,
      _bindings,
      _buffers,
      callbacks,
    ));
  }

  void execute(Pointer<interactor_message_t> message) => _consumers[message.ref.owner_id].execute(message);
}