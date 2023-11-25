import 'dart:ffi';

import 'notifications.dart';
import 'producer.dart';

abstract interface class InteractorConsumer {
  List<InteractorCallback> callbacks();
}

class InteractorCallback {
  final void Function(InteractorNotification notification) callback;

  InteractorCallback(this.callback);
}

abstract interface class InteractorProducer {
  void initialize(InteractorProducerExecutor executor);
}

class InteractorMethod {
  final Pointer<NativeFunction<Void Function(InteractorNotification)>> method;

  InteractorMethod(this.method);
}
