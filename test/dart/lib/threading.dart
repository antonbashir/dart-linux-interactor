import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/message.dart';
import 'package:linux_interactor/interactor/worker.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:linux_interactor_test/test.dart';
import 'package:test/test.dart';

void testThreadingNative() {
  test("[isolates]dart(bytes) <-> [threads]native(bytes)", () async {
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
      final isolate = Isolate.spawn<List<dynamic>>(
        _callNativeIsolate,
        onError: errorPort.sendPort,
        [messages, interactor.worker(InteractorDefaults.worker()), exitPort.sendPort],
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

    exitPorts.forEach((port) => port.close());
    errorPorts.forEach((port) => port.close());

    bindings.test_threading_destroy();
    await interactor.shutdown();
  });
}

void testThreadingDart() {
  test("[threads]native(bytes) <-> [isolates]dart(bytes)", () async {
    final interactor = Interactor();
    final messages = 1024;
    final isolates = 4;
    final threads = 4;

    final bindings = loadBindings();
    bindings.test_threading_initialize(threads, messages * isolates);

    final spawnedIsolates = <Future<Isolate>>[];
    final descriptorPorts = <ReceivePort>[];
    final exitPorts = <ReceivePort>[];
    final errorPorts = <ReceivePort>[];

    for (var isolate = 0; isolate < isolates; isolate++) {
      final descriptorPort = ReceivePort();
      descriptorPorts.add(descriptorPort);
      final exitPort = ReceivePort();
      exitPorts.add(exitPort);
      final errorPort = ReceivePort();
      errorPorts.add(errorPort);
      final isolate = Isolate.spawn<List<dynamic>>(
        _callDartIsolate,
        onError: errorPort.sendPort,
        [messages, interactor.worker(InteractorDefaults.worker()), descriptorPort.sendPort, exitPort.sendPort],
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

    final descriptors = await Future.wait(descriptorPorts.map((port) => port.first));
    descriptors.forEach((descriptor) {
      for (var messageId = 0; messageId < messages; messageId++) {
        bindings.test_threading_call_dart_bytes(descriptor, 0, (malloc<Uint8>(3)..asTypedList(3).setAll(0, [1, 2, 3])), 3);
      }
    });

    while (bindings.test_threading_call_dart_check() < messages * isolates) await Future.delayed(Duration(milliseconds: 100));
    await Future.wait(exitPorts.map((port) => port.first));

    bindings.test_threading_destroy();

    exitPorts.forEach((port) => port.close());
    errorPorts.forEach((port) => port.close());

    await interactor.shutdown();
  });
}

Future<void> _callNativeIsolate(List<dynamic> input) async {
  final messages = input[0];
  final bindings = loadBindings();
  final threads = bindings.test_threading_threads();
  final calls = <Future<InteractorCall>>[];
  final worker = InteractorWorker(input[1]);
  await worker.initialize();
  final producer = worker.producer(TestNativeProducer(bindings));
  worker.activate();
  for (var threadId = 0; threadId < threads.ref.count; threadId++) {
    final interactor = threads.ref.threads.elementAt(threadId).value.ref.interactor;
    for (var messageId = 0; messageId < messages; messageId++) {
      calls.add(producer.testThreadingCallNative(interactor.ref.ring.ref.ring_fd, configurator: (message) => message..setInputBuffer([1, 2, 3])));
    }
  }
  (await Future.wait(calls)).forEach((result) {
    if (!ListEquality().equals(result.outputBuffer, [1, 2, 3])) {
      throw TestFailure("outputBuffer != ${[1, 2, 3]}");
    }
    result.releaseOutputBuffer();
    result.release();
  });
  input[2].send(null);
}

Future<void> _callDartIsolate(List<dynamic> input) async {
  final messages = input[0];
  final worker = InteractorWorker(input[1]);
  await worker.initialize();
  var count = 0;

  final completer = Completer();

  worker.consumer(TestNativeConsumer(
    (message) {
      if (!ListEquality().equals(message.inputBytes, [1, 2, 3])) {
        completer.completeError(throw TestFailure("inputBytes != ${[1, 2, 3]}"));
      }
      if (++count == messages) {
        completer.complete();
      }
    },
  ));
  worker.activate();

  input[2].send(worker.descriptor);

  await completer.future;

  input[3].send(null);
}
