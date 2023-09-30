import 'dart:ffi';

import 'bindings.dart';
import 'producer.dart';

abstract interface class NativeConsumer {
  List<NativeCallback> callbacks();
}

class NativeCallback {
  final void Function(Pointer<interactor_message_t> message) callback;

  NativeCallback(this.callback);
}

abstract class NativeProducer {
  late final NativeProducerExecutor _executor;

  void initialize(NativeProducerExecutor executor) => this._executor = executor;

  NativeMethodExecutor of(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) => _executor.of(pointer);

  List<NativeMethod> methods();
}

class NativeMethod {
  final Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> method;

  NativeMethod(this.method);
}
