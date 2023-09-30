import 'dart:ffi';

import 'package:linux_interactor/interactor/bindings.dart';
import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';

class TestNativeConsumer implements NativeConsumer {
  void test(Pointer<interactor_message_t> message) {
    print("Hello, C");
  }

  @override
  List<NativeCallback> callbacks() => [NativeCallback(test)];
}

class TestNativeProducer extends NativeProducer {
  final InteractorBindings _bindings;
  TestNativeProducer(this._bindings);

  late final testMethod = of(_bindings.addresses.test_method);

  @override
  List<NativeMethod> methods() => [NativeMethod(_bindings.addresses.test_method)];
}

Future<void> main() async {
  final interactor = Interactor();
  final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
  await worker.initialize();
  worker.consumer(TestNativeConsumer());

  final producer = worker.producer(TestNativeProducer(interactor.bindings));
  worker.activate();

  final native = interactor.bindings.test_initialize(worker.descriptor);
  producer.testMethod.execute(native.ref.ring.ref.ring_fd);
  interactor.bindings.test_check(native);
}
