import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';
import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:linux_interactor_test/test.dart';
import 'package:test/test.dart';

void testCallNative() {
  test("dart(bool) <-> native(bool)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_native_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    final call = producer.testCallNativeEcho(native.ref.ring.ref.ring_fd, configurator: (message) => message..setInputBool(true));
    while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
    final result = await call;
    expect(result.getOutputBool(), true);
    result.free();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(int) <-> native(int)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_native_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    final call = producer.testCallNativeEcho(native.ref.ring.ref.ring_fd, configurator: (message) => message..setInputInt(123));
    while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
    final result = await call;
    expect(result.getOutputInt(), 123);
    result.free();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(double) <-> native(double)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_native_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    final call = producer.testCallNativeEcho(native.ref.ring.ref.ring_fd, configurator: (message) => message..setInputDouble(123.45));
    while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
    final result = await call;
    expect(result.getOutputDouble(), 123.45);
    result.free();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(string) <-> native(string)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_native_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    final call = producer.testCallNativeEcho(native.ref.ring.ref.ring_fd, configurator: (message) => message..setInputString("test"));
    while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
    final result = await call;
    expect(result.getOutputString(), "test");
    result.free();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(object) <-> native(object)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_native_reset();
    await worker.initialize();
    worker.payloads.register<test_object>(sizeOf<test_object>());
    worker.payloads.register<test_object_child>(sizeOf<test_object_child>());
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    final call = producer.testCallNativeEcho(native.ref.ring.ref.ring_fd,
        configurator: (message) => message
          ..setInputObject<test_object>(
            (object) {
              object.ref.field = 123;
              object.ref.child_field = worker.payloads.allocate<test_object_child>().ref;
              object.ref.child_field.field = 456;
            },
          ));
    while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
    final result = await call;
    final output = result.getOutputObject<test_object>().ref;
    expect(output.field, 123);
    expect(output.child_field.field, 456);
    result.free();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(buffer) <-> native(buffer)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_native_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    final call = producer.testCallNativeEcho(native.ref.ring.ref.ring_fd, configurator: (message) => message..setInputBuffer([1, 2, 3]));
    while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
    final result = await call;
    expect(true, ListEquality().equals(result.getOutputBuffer(), [1, 2, 3]));
    result.free();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(bytes) <-> native(bytes)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_native_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.consumer(TestNativeConsumer());
    worker.activate();
    final call = producer.testCallNativeEcho(native.ref.ring.ref.ring_fd, configurator: (message) => message..setInputBytes([1, 2, 3]));
    while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
    final result = await call;
    expect(true, ListEquality().equals(result.getOutputBytes(), [1, 2, 3]));
    result.free();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });
}

void testCallDart() {
  test("native(output) <-> dart(input)", () async {
    // final interactor = Interactor();
    // final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    // final bindings = loadBindings();
    // await worker.initialize();
    // final native = bindings.test_interactor_initialize();
    // final producer = worker.producer(TestNativeProducer(bindings));
    // worker.consumer(TestNativeConsumer());
    // worker.activate();
    // producer.testCallNative(native.ref.ring.ref.ring_fd);
    // bindings.test_call_native_check(native);
    // await interactor.shutdown();
  });
}
