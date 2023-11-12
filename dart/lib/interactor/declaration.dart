import 'dart:ffi';

import 'messages.dart';
import 'producer.dart';

abstract interface class NativeConsumer {
  List<NativeCallback> callbacks();
}

class NativeCallback {
  final void Function(InteractorNotification notification) callback;

  NativeCallback(this.callback);
}

abstract interface class NativeProducer {
  void initialize(NativeProducerExecutor executor);
}

class NativeMethod {
  final Pointer<NativeFunction<Void Function(InteractorNotification)>> method;

  NativeMethod(this.method);
}
