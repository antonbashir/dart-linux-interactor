import 'dart:ffi';

import 'bindings.dart';
import 'producer.dart';

abstract interface class NativeConsumerDeclaration {
  List<NativeCallbackDeclaration> callbacks();
}

class NativeCallbackDeclaration {
  final void Function(Pointer<interactor_message_t> message) callback;

  NativeCallbackDeclaration(this.callback);
}

abstract class NativeProducerProvider {
  late final NativeProducer _producer;

  void initialize(NativeProducer producer) => this._producer = producer;

  NativeMethod of(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) => _producer.of(pointer);

  List<NativeMethodDeclaration> methods();
}

class NativeMethodDeclaration {
  final Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> method;

  NativeMethodDeclaration(this.method);
}
