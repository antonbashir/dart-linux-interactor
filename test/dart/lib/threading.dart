import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:linux_interactor/interactor/bindings.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/message.dart';
import 'package:linux_interactor/interactor/worker.dart';
import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:linux_interactor_test/test.dart';
import 'package:test/test.dart';

void testThreadingNative() {
  test("[isolates]dart(string) <-> [threads]native(string)", () async {
    final interactor = Interactor();
    final messages = 1024;
    final isolates = 4;
    final threads = 4;

    final bindings = loadBindings();
    bindings.test_threading_initialize(threads, messages * isolates);
    final spawnedIsolates = <Future<Isolate>>[];
    final exitPorts = <ReceivePort>[];
    final errorPorts = <ReceivePort>[];

    for (var isolate = 0; isolate < isolates; isolate++) {
      final exitPort = ReceivePort();
      exitPorts.add(exitPort);
      final errorPort = ReceivePort();
      errorPorts.add(errorPort);
      final isolate = Isolate.spawn<List<SendPort>>(
        _callNativeIsolate,
        onError: errorPort.sendPort,
        [interactor.worker(InteractorDefaults.worker()), exitPort.sendPort],
      );
      spawnedIsolates.add(isolate);
    }

    errorPorts.forEach(
      (element) => element.listen((message) {
        exitPorts.forEach((port) => port.close());
        errorPorts.forEach((port) => port.close());
        fail(message.toString());
      }),
    );

    await Future.wait(spawnedIsolates);
    while (bindings.test_threading_call_native_check() < messages * isolates) await Future.delayed(Duration(milliseconds: 100));
    await Future.wait(exitPorts.map((port) => port.first));

    bindings.test_threading_destroy();

    exitPorts.forEach((port) => port.close());
    errorPorts.forEach((port) => port.close());

    await interactor.shutdown();
  });
}

Future<void> _callNativeIsolate(List<SendPort> input) async {
  final messages = 1024;
  final bindings = loadBindings();
  final threads = bindings.test_threading_threads();
  final calls = <Future<InteractorCall>>[];
  final worker = InteractorWorker(input[0]);
  await worker.initialize();
  final producer = worker.producer(TestNativeProducer(bindings));
  worker.activate();
  for (var threadId = 0; threadId < threads.ref.count; threadId++) {
    final interactor = threads.ref.threads.elementAt(threadId).value.ref.interactor;
    for (var messageId = 0; messageId < messages; messageId++) {
      calls.add(producer.testThreadingCallNativeEcho(interactor.ref.ring.ref.ring_fd, configurator: (message) => message..setInputBuffer([1, 2, 3])));
    }
  }
  final results = await Future.wait(calls);
  results.forEach((result) {
    if (!ListEquality().equals(result.outputBuffer, [1, 2, 3])) {
      throw TestFailure("outputBuffer != ${[1, 2, 3]}");
    }
    result.releaseOutputBuffer();
    result.release();
  });
  input[1].send(null);
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
