import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'calls.dart';
import 'notifications.dart';

typedef InteractorCallback = FutureOr<void> Function(InteractorNotification notification);

abstract interface class InteractorConsumer {
  List<InteractorCallback> callbacks();
}

abstract interface class InteractorProducerRegistrat {
  InteractorMethod register(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer);
}

abstract interface class InteractorProducer {
  void initialize(InteractorProducerRegistrat registrat);
}

abstract interface class InteractorMethod {
  Future<InteractorCall> call(int target, {FutureOr<void> Function(InteractorCall message)? configurator});
}
