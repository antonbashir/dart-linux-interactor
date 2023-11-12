import 'dart:ffi';

import 'bindings.dart';
import 'consumer.dart';
import 'declaration.dart';

class InteractorConsumerRegistry {
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;

  InteractorConsumerRegistry(
    this._interactorPointer,
    this._bindings,
  );

  final _consumers = <NativeConsumerExecutor>[];

  void register(NativeConsumer declaration) {
    final callbacks = <NativeCallbackExecutor>[];
    for (var callback in declaration.callbacks()) {
      callbacks.add(NativeCallbackExecutor(callbacks.length, _bindings, _interactorPointer, callback.callback));
    }
    _consumers.add(NativeConsumerExecutor(
      _consumers.length,
      _interactorPointer,
      _bindings,
      callbacks,
    ));
  }

  void call(Pointer<interactor_message_t> message) => _consumers[message.ref.owner].call(message);
}
