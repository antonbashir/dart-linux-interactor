import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:linux_interactor/interactor/bindings.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';
import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:linux_interactor_test/test.dart';
import 'package:test/test.dart';

void testThreadingNative() {
  test("[isolates]dart(string) <-> [threads]native(string)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final producer = worker.producer(TestNativeProducer(bindings));
    worker.activate();
    final call = producer.testCallNativeEcho(native.ref.ring.ref.ring_fd, configurator: (message) => message..setInputString("test"));
    while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
    final result = await call;
    expect(result.outputString, "test");
    result.release();
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });
}

void testThreadingDart() {
  test("[threads]native(string) <-> [isolates]dart(string)", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    final bindings = loadBindings();
    bindings.test_call_reset();
    await worker.initialize();
    final native = bindings.test_interactor_initialize();
    final completer = Completer();
    worker.consumer(TestNativeConsumer(
      (message) {
        expect(message.inputString, "test");
        completer.complete();
      },
    ));
    worker.activate();
    bindings.test_call_dart_string(native, worker.descriptor, 0, "test".toNativeUtf8().cast());
    while (true) {
      final result = bindings.test_call_dart_check(native);
      if (result == nullptr) {
        await Future.delayed(Duration(milliseconds: 100));
        continue;
      }
      break;
    }
    await completer.future;
    await interactor.shutdown();
    bindings.test_interactor_destroy(native);
  });
}

Future<void> _awaitDartCall(TestBindings bindings, Pointer<interactor_native_t> native) async {
  while (true) {
    final result = bindings.test_call_dart_check(native);
    if (result == nullptr) {
      await Future.delayed(Duration(milliseconds: 100));
      continue;
    }
    break;
  }
}

Future<void> _awaitNativeCall(TestBindings bindings, Pointer<interactor_native_t> native) async {
  while (!bindings.test_call_native_check(native)) await Future.delayed(Duration(milliseconds: 100));
}
