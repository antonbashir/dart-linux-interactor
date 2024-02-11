import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';

typedef InteractorCallback = FutureOr<void> Function(Pointer<interactor_message> notification);

abstract interface class InteractorConsumer {
  List<InteractorCallback> callbacks();
}

abstract interface class InteractorProducerRegistrat {
  InteractorMethod register(Pointer<NativeFunction<Void Function(Pointer<interactor_message>)>> pointer);
}

abstract interface class InteractorProducer {
  void initialize(InteractorProducerRegistrat registrat);
}

abstract interface class InteractorMethod {
  Future<Pointer<interactor_message>> call(int target, Pointer<interactor_message> message);
}
