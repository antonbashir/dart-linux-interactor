import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:linux_interactor/interactor/bindings.dart';
import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';

import 'bindings.dart';

class TestNativeConsumer implements NativeConsumerDeclaration {
  void test(Pointer<interactor_message_t> message) {
    print("Hello, C");
  }

  @override
  List<NativeCallbackDeclaration> callbacks() => [NativeCallbackDeclaration(test)];
}

class TestNativeProducer extends NativeProducerProvider {
  final TestBindings _bindings;

  TestNativeProducer(this._bindings);

  late final testMethod = of(_bindings.addresses.test_method);

  @override
  List<NativeMethodDeclaration> methods() => [NativeMethodDeclaration(_bindings.addresses.test_method)];
}

Future<void> main() async {
  final bindings = TestBindings(DynamicLibrary.open("/home/anton/development/evolution/dart-linux-interactor/test/dart/native/libinteractortest.so"));
  final interactor = Interactor();
  final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
  await worker.initialize();
  worker.consumer(TestNativeConsumer());
  final provider = worker.producer(TestNativeProducer(bindings));
  worker.activate();
  provider.testMethod.execute(bindings.test_void(worker.descriptor), calloc<interactor_message_t>());
  bindings.test_check();
}
