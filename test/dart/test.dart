import 'dart:ffi';

import 'package:linux_interactor/interactor/bindings.dart';
import 'bindings.dart';
import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';

class TestNativeConsumer implements NativeConsumerDeclaration {
  void test(Pointer<interactor_message_t> message) {
    print("Hello, C");
  }

  @override
  List<NativeCallbackDeclaration> callbacks() => [NativeCallbackDeclaration(test)];
}

class TestNativeService implements NativeServiceDeclaration {
  final TestBindings _bindings;

  TestNativeService(this._bindings);

  @override
  List<NativeMethodDeclaration> methods() => [NativeMethodDeclaration(_bindings.addresses.test_method)];
}

Future<void> main() async {
  final interactor = Interactor();
  final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
  await worker.initialize();
  worker.consumer(TestNativeConsumer());
  worker.activate();
  TestBindings(DynamicLibrary.open("/home/anton/development/evolution/dart-linux-interactor/test/dart/native/libinteractortest.so")).test_void(worker.descriptor);
}
