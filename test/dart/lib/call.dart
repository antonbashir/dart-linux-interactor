import 'dart:async';
import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';
import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:linux_interactor_test/test.dart';
import 'package:test/test.dart';

void testCallNative() {
  test("dart(null) <-> native(null)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNative(native.ref.descriptor);
    await _awaitNativeCall(bindings, native);
    final result = await call;
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(bool) <-> native(bool)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNative(native.ref.descriptor, configurator: (message) => message.setInputBool(true));
    await _awaitNativeCall(bindings, native);
    final result = await call;
    expect(result.outputBool, true);
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(int) <-> native(int)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNative(native.ref.descriptor, configurator: (message) => message.setInputInt(123));
    await _awaitNativeCall(bindings, native);
    final result = await call;
    expect(result.outputInt, 123);
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(double) <-> native(double)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNative(native.ref.descriptor, configurator: (message) => message.setInputDouble(123.45));
    await _awaitNativeCall(bindings, native);
    final result = await call;
    expect(result.outputDouble, 123.45);
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(string) <-> native(string)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNative(native.ref.descriptor, configurator: (message) => message.setInputString("test"));
    await _awaitNativeCall(bindings, native);
    final result = await call;
    expect(result.getOutputString(), "test");
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(object) <-> native(object)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    worker.payloads.register<test_object>(sizeOf<test_object>());
    worker.payloads.register<test_object_child>(sizeOf<test_object_child>());
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNative(native.ref.descriptor,
        configurator: (message) => message
          ..setInputObject<test_object>(
            (object) {
              object.ref.field = 123;
              object.ref.child_field = worker.payloads.allocate<test_object_child>().ref;
              object.ref.child_field.field = 456;
            },
          ));
    await _awaitNativeCall(bindings, native);
    final result = await call;
    final output = result.getOutputObject<test_object>().ref;
    expect(output.field, 123);
    expect(output.child_field.field, 456);
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(buffer) <-> native(buffer)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNative(native.ref.descriptor, configurator: (message) => message.setInputBuffer([1, 2, 3]));
    await _awaitNativeCall(bindings, native);
    final result = await call;
    expect(true, ListEquality().equals(result.outputBuffer, [1, 2, 3]));
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("dart(bytes) <-> native(bytes)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNative(native.ref.descriptor, configurator: (message) => message.setInputBytes([1, 2, 3]));
    await _awaitNativeCall(bindings, native);
    final result = await call;
    expect(true, ListEquality().equals(result.outputBytes, [1, 2, 3]));
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });
}

void testCallDart() {
  test("native(null) <-> dart(null)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer((message) => completer.complete()));
    worker.activate();
    bindings.test_call_dart_bool(native, worker.descriptor, 0, true);
    await _awaitDartCall(bindings, native);
    await completer.future;
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("native(bool) <-> dart(bool)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.inputBool, true);
        completer.complete();
      },
    ));
    worker.activate();
    bindings.test_call_dart_bool(native, worker.descriptor, 0, true);
    await _awaitDartCall(bindings, native);
    await completer.future;
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("native(int) <-> dart(int)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.inputInt, 123);
        completer.complete();
      },
    ));
    worker.activate();
    bindings.test_call_dart_int(native, worker.descriptor, 0, 123);
    await _awaitDartCall(bindings, native);
    await completer.future;
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("native(double) <-> dart(double)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.inputDouble, 123.45);
        completer.complete();
      },
    ));
    worker.activate();
    bindings.test_call_dart_double(native, worker.descriptor, 0, 123.45);
    await _awaitDartCall(bindings, native);
    await completer.future;
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("native(string) <-> dart(string)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.getInputString(), "test");
        completer.complete();
      },
    ));
    worker.activate();
    bindings.test_call_dart_string(native, worker.descriptor, 0, "test".toNativeUtf8().cast());
    await _awaitDartCall(bindings, native);
    await completer.future;
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("native(object) <-> dart(object)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.getInputObject<test_object>().ref.field, 123);
        completer.complete();
      },
    ));
    worker.activate();
    bindings.test_call_dart_object(native, worker.descriptor, 0, 123);
    await _awaitDartCall(bindings, native);
    await completer.future;
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });

  test("native(bytes) <-> dart(bytes)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(true, ListEquality().equals(message.inputBytes, [1, 2, 3]));
        completer.complete();
      },
    ));
    worker.activate();
    bindings.test_call_dart_bytes(native, worker.descriptor, 0, (malloc<Uint8>(3)..asTypedList(3).setAll(0, [1, 2, 3])), 3);
    await _awaitDartCall(bindings, native);
    await completer.future;
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });
}

Future<void> _awaitDartCall(TestBindings bindings, Pointer<interactor_native_t> native) async {
  while (true) {
    final result = bindings.test_call_dart_check(native);
    if (result == nullptr) {
      await Future.delayed(Duration(milliseconds: 10));
      continue;
    }
    break;
  }
}

Future<void> _awaitNativeCall(TestBindings bindings, Pointer<interactor_native_t> native) async {
  while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 10));
}
