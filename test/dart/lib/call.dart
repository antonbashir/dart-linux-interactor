import 'dart:async';
import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:linux_interactor/linux_interactor.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:test/test.dart';

import 'bindings.dart';

void testCallNative() {
  test("dart(null) <-> native(null)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer());
    worker.activate();
    final call = producer.testCallNative(test_interactor_descriptor(native), worker.messages.allocate());
    await _awaitNativeCall(native);
    final result = await call;
    worker.messages.free(result);
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("dart(bool) <-> native(bool)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer());
    worker.activate();
    final call = producer.testCallNative(test_interactor_descriptor(native), worker.messages.allocate()..setInputBool(true));
    await _awaitNativeCall(native);
    final result = await call;
    expect(result.outputBool, true);
    worker.messages.free(result);
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("dart(int) <-> native(int)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer());
    worker.activate();
    final call = producer.testCallNative(test_interactor_descriptor(native), worker.messages.allocate()..setInputInt(123));
    await _awaitNativeCall(native);
    final result = await call;
    expect(result.outputInt, 123);
    worker.messages.free(result);
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("dart(double) <-> native(double)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer());
    worker.activate();
    final call = producer.testCallNative(test_interactor_descriptor(native), worker.messages.allocate()..setInputDouble(worker.datas, 123.45));
    await _awaitNativeCall(native);
    final result = await call;
    expect(result.outputDouble, 123.45);
    worker.messages.free(result);
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("dart(string) <-> native(string)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer());
    worker.activate();
    final call = producer.testCallNative(test_interactor_descriptor(native), worker.messages.allocate()..setInputString(worker.datas, "test"));
    await _awaitNativeCall(native);
    final result = await call;
    expect(result.getOutputString(), "test");
    worker.messages.free(result);
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("dart(object) <-> native(object)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    worker.payloads.register<test_object>(sizeOf<test_object>());
    worker.payloads.register<test_object_child>(sizeOf<test_object_child>());
    final native = test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer());
    worker.activate();
    final call = producer.testCallNative(
        test_interactor_descriptor(native),
        worker.messages.allocate()
          ..setInputObject<test_object>(
            worker.payloads,
            (object) {
              object.ref.field = 123;
              object.ref.child_field = worker.payloads.allocate<test_object_child>().ref;
              object.ref.child_field.field = 456;
            },
          ));
    await _awaitNativeCall(native);
    final result = await call;
    final output = result.getOutputObject<test_object>().ref;
    expect(output.field, 123);
    expect(output.child_field.field, 456);
    worker.messages.free(result);
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("dart(buffer) <-> native(buffer)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer());
    worker.activate();
    final call = producer.testCallNative(test_interactor_descriptor(native), worker.messages.allocate()..setInputStaticBuffer(worker.staticBuffers, [1, 2, 3]));
    await _awaitNativeCall(native);
    final result = await call;
    expect(true, ListEquality().equals(result.getOutputStaticBuffer(worker.staticBuffers), [1, 2, 3]));
    worker.messages.free(result);
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("dart(bytes) <-> native(bytes)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer());
    worker.activate();
    final call = producer.testCallNative(test_interactor_descriptor(native), worker.messages.allocate()..setInputBytes(worker.datas, [1, 2, 3]));
    await _awaitNativeCall(native);
    final result = await call;
    expect(true, ListEquality().equals(result.outputBytes, [1, 2, 3]));
    worker.messages.free(result);
    await interactor.shutdown();
    test_interactor_destroy(native);
  });
}

void testCallDart() {
  test("native(null) <-> dart(null)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer((message) => completer.complete()));
    worker.activate();
    test_call_dart_bool(native, worker.descriptor, 0, true);
    await _awaitDartCall(native);
    await completer.future;
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("native(bool) <-> dart(bool)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.inputBool, true);
        completer.complete();
      },
    ));
    worker.activate();
    test_call_dart_bool(native, worker.descriptor, 0, true);
    await _awaitDartCall(native);
    await completer.future;
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("native(int) <-> dart(int)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.inputInt, 123);
        completer.complete();
      },
    ));
    worker.activate();
    test_call_dart_int(native, worker.descriptor, 0, 123);
    await _awaitDartCall(native);
    await completer.future;
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("native(double) <-> dart(double)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.inputDouble, 123.45);
        completer.complete();
      },
    ));
    worker.activate();
    test_call_dart_double(native, worker.descriptor, 0, 123.45);
    await _awaitDartCall(native);
    await completer.future;
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("native(string) <-> dart(string)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.getInputString(), "test");
        completer.complete();
      },
    ));
    worker.activate();
    test_call_dart_string(native, worker.descriptor, 0, "test".toNativeUtf8().cast());
    await _awaitDartCall(native);
    await completer.future;
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("native(object) <-> dart(object)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.getInputObject<test_object>().ref.field, 123);
        completer.complete();
      },
    ));
    worker.activate();
    test_call_dart_object(native, worker.descriptor, 0, 123);
    await _awaitDartCall(native);
    await completer.future;
    await interactor.shutdown();
    test_interactor_destroy(native);
  });

  test("native(bytes) <-> dart(bytes)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));

    test_call_reset();
    await worker.initialize();
    final native = test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(true, ListEquality().equals(message.inputBytes, [1, 2, 3]));
        completer.complete();
      },
    ));
    worker.activate();
    test_call_dart_bytes(native, worker.descriptor, 0, (ffi.calloc<Uint8>(3)..asTypedList(3).setAll(0, [1, 2, 3])), 3);
    await _awaitDartCall(native);
    await completer.future;
    await interactor.shutdown();
    test_interactor_destroy(native);
  });
}

Future<void> _awaitDartCall(Pointer<interactor_native> native) async {
  while (true) {
    final result = test_call_dart_check(native);
    if (result == nullptr) {
      await Future.delayed(Duration(milliseconds: 10));
      continue;
    }
    break;
  }
}

Future<void> _awaitNativeCall(Pointer<interactor_native> native) async {
  while (!test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 10));
}
