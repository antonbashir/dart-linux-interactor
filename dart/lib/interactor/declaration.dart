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

abstract interface class NativeProducer {
  void initialize(NativeProducerExecutor executor);
}

class NativeMethod {
  final Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> method;

  NativeMethod(this.method);
}
