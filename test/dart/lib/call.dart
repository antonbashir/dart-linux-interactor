import 'dart:ffi';

import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:linux_interactor_test/test.dart';
import 'package:test/test.dart';

void testCallNative() {
  test("dart(output) <-> native(input)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    producer.testCallNative(native.ref.ring.ref.ring_fd);
    bindings.test_run_native_check(native);
    await interactor.shutdown();
  });
}

void testCallDart() {
  test("native(output) <-> dart(input)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    producer.testCallNative(native.ref.ring.ref.ring_fd);
    bindings.test_run_native_check(native);
    await interactor.shutdown();
  });
}