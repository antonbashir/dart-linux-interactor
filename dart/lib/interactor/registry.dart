import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'consumer.dart';
import 'declaration.dart';

class InteractorConsumerRegistry {
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  InteractorConsumerRegistry(
    this._interactorPointer,
    this._bindings,
    this._buffers,
  );

  final _consumers = <NativeConsumerExecutor>[];

  void register(NativeConsumer declaration) {
    final callbacks = <NativeCallbackExecutor>[];
    for (var callback in declaration.callbacks()) {
      callbacks.add(NativeCallbackExecutor(callbacks.length, callback.callback));
    }
    _consumers.add(NativeConsumerExecutor(
      _consumers.length,
      _interactorPointer,
      _bindings,
      _buffers,
      callbacks,
    ));
  }

  void execute(Pointer<interactor_message_t> message) => _consumers[message.ref.owner_id].execute(message);
}
