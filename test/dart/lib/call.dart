import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';
import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void testCall() {
  test("dart -> native", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = TestBindings(DynamicLibrary.open("${dirname(Platform.script.toFilePath())}/../native/libinteractortest.so"));
    await worker.initialize();
    worker.consumer(TestNativeConsumer());
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final native = interactor.bindings.interactor_native_initialize_default(malloc<interactor_native>().cast(), 0);
    await interactor.shutdown();
  });
}
