import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart' as ffi;

import 'bindings.dart';
import 'configuration.dart';
import 'constants.dart';
import 'exception.dart';
import 'lookup.dart';

class Interactor {
  final _workerClosers = <SendPort>[];
  final _workerPorts = <RawReceivePort>[];
  final _workerDestroyer = ReceivePort();

  Interactor({String? libraryPath, bool load = true}) {
    if (load) {
      InteractorLibrary.load(libraryPath: libraryPath);
    }
  }

  Future<void> shutdown() async {
    _workerClosers.forEach((worker) => worker.send(null));
    await _workerDestroyer.take(_workerClosers.length).toList();
    _workerDestroyer.close();
    _workerPorts.forEach((port) => port.close());
  }

  SendPort worker(InteractorConfiguration configuration) {
    final port = RawReceivePort((ports) async {
      SendPort toWorker = ports[0];
      _workerClosers.add(ports[1]);
      final interactorPointer = ffi.calloc<interactor_dart>(sizeOf<interactor_dart>());
      if (interactorPointer == nullptr) throw InteractorInitializationException(InteractorErrors.workerMemoryError);
      final result = ffi.using((arena) {
        final nativeConfiguration = arena<interactor_dart_configuration>();
        nativeConfiguration.ref.ring_flags = configuration.ringFlags;
        nativeConfiguration.ref.ring_size = configuration.ringSize;
        nativeConfiguration.ref.static_buffer_size = configuration.staticBufferSize;
        nativeConfiguration.ref.static_buffers_capacity = configuration.staticBuffersCapacity;
        nativeConfiguration.ref.base_delay_micros = configuration.baseDelay.inMicroseconds;
        nativeConfiguration.ref.max_delay_micros = configuration.maxDelay.inMicroseconds;
        nativeConfiguration.ref.delay_randomization_factor = configuration.delayRandomizationFactor;
        nativeConfiguration.ref.cqe_peek_count = configuration.cqePeekCount;
        nativeConfiguration.ref.cqe_wait_count = configuration.cqeWaitCount;
        nativeConfiguration.ref.cqe_wait_timeout_millis = configuration.cqeWaitTimeout.inMilliseconds;
        nativeConfiguration.ref.slab_size = configuration.memorySlabSize;
        nativeConfiguration.ref.preallocation_size = configuration.memoryPreallocationSize;
        nativeConfiguration.ref.quota_size = configuration.memoryQuotaSize;
        return interactor_dart_initialize(interactorPointer, nativeConfiguration, _workerClosers.length);
      });
      if (result < 0) {
        interactor_dart_destroy(interactorPointer);
        ffi.calloc.free(interactorPointer);
        throw InteractorInitializationException(InteractorErrors.workerError(result));
      }
      final workerInput = [interactorPointer.address, _workerDestroyer.sendPort, result];
      toWorker.send(workerInput);
    });
    _workerPorts.add(port);
    return port.sendPort;
  }
}
