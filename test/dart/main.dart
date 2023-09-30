import 'dart:ffi';

import 'package:linux_interactor/interactor/bindings.dart';
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

Future<void> main() async {
  final interactor = Interactor();
  final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
  await worker.initialize();
  worker.consumer(TestNativeConsumer());
  worker.activate();
}
