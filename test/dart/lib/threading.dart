import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:linux_interactor/linux_interactor.dart';
import 'package:linux_interactor_test/consumer.dart';
import 'package:linux_interactor_test/producer.dart';
import 'package:test/test.dart';

import 'bindings.dart';

void testThreadingNative() {
  test("[isolates]dart(bytes) <-> [threads]native(bytes)", () async {
    final interactor = Interactor();
    final messages = 16;
    final isolates = 4;
    final threads = 8;

    if (!test_threading_initialize(threads, isolates, messages * isolates)) {
      fail("native thread failed ");
    }

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
        [messages, threads, interactor.worker(InteractorDefaults.worker()), exitPort.sendPort],
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
    while (test_threading_call_native_check() != messages * isolates * threads) await Future.delayed(Duration(milliseconds: 1));
    await Future.wait(exitPorts.map((port) => port.first));

    exitPorts.forEach((port) => port.close());
    errorPorts.forEach((port) => port.close());

    test_threading_destroy();
    await interactor.shutdown();
  });
}

void testThreadingDart() {
  test("[threads]native(bytes) <-> [isolates]dart(bytes)", () async {
    final interactor = Interactor();
    final messages = 16;
    final isolates = 4;
    final threads = 8;

    if (!test_threading_initialize(threads, isolates, messages * isolates)) {
      fail("native thread failed ");
    }

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
        [messages * threads, interactor.worker(InteractorDefaults.worker()), descriptorPort.sendPort, exitPort.sendPort],
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
    final descriptors = (await Future.wait(descriptorPorts.map((port) => port.first))).map((descriptor) => descriptor as int).toList();
    final Pointer<Int32> descriptorsNative = ffi.calloc(descriptors.length * sizeOf<Int32>());
    descriptors.forEachIndexed((index, element) => descriptorsNative[index] = element);
    test_threading_prepare_call_dart_bytes(descriptorsNative, descriptors.length);

    while (test_threading_call_dart_check() != messages * threads * isolates) await Future.delayed(Duration(milliseconds: 1));
    await Future.wait(exitPorts.map((port) => port.first));

    exitPorts.forEach((port) => port.close());
    errorPorts.forEach((port) => port.close());

    test_threading_destroy();
    await interactor.shutdown();
  });
}

Future<void> _callNativeIsolate(List<dynamic> input) async {
  final messages = input[0];
  final threads = input[1];
  final calls = <Future<Pointer<interactor_message>>>[];
  final worker = InteractorWorker(input[2]);
  await worker.initialize();
  final producer = worker.producer(TestNativeProducer());
  worker.activate();
  final descriptors = test_threading_interactor_descriptors();
  for (var threadId = 0; threadId < threads; threadId++) {
    final descriptor = descriptors.elementAt(threadId);
    if (descriptor == nullptr) {
      fail("descriptor is null");
    }
    for (var messageId = 0; messageId < messages; messageId++) {
      final message = worker.messages.allocate();
      message.setInputStaticBuffer(worker.staticBuffers, [1, 2, 3]);
      calls.add(producer.testThreadingCallNative(descriptor.value, message));
    }
  }
  (await Future.wait(calls)).forEach((result) {
    if (!ListEquality().equals(result.getOutputStaticBuffer(worker.staticBuffers), [1, 2, 3])) {
      throw TestFailure("outputBuffer != ${[1, 2, 3]}. ${result.outputSize}: ${result.getOutputStaticBuffer(worker.staticBuffers)}");
    }
    worker.staticBuffers.release(result.inputInt);
    worker.messages.free(result);
  });
  input[3].send(null);
}

Future<void> _callDartIsolate(List<dynamic> input) async {
  final messages = input[0];
  final worker = InteractorWorker(input[1]);
  await worker.initialize();
  var count = 0;
  final completer = Completer();
  worker.consumer(TestNativeConsumer(
    (notification) {
      if (!ListEquality().equals(notification.inputBytes, [1, 2, 3])) {
        completer.completeError(TestFailure("inputBytes != ${[1, 2, 3]}. ${notification.inputSize}: ${notification.inputBytes}"));
        return;
      }
      if (++count == messages) {
        completer.complete();
        return;
      }
    },
  ));
  worker.activate();

  input[2].send(worker.descriptor);

  await completer.future;

  input[3].send(null);
}
