import 'dart:ffi';
import 'dart:io';

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

Future<void> main() async {
  final interactor = Interactor();
  final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
  await worker.initialize();
  worker.consumer(TestNativeConsumer());
  worker.activate();
  TestBindings(DynamicLibrary.open("/home/anton/development/evolution/dart-linux-interactor/test/dart/native/libinteractortest.so")).test_void(worker.descriptor);
}
