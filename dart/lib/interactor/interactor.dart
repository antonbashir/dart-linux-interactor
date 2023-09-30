import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'configuration.dart';
import 'constants.dart';
import 'exception.dart';
import 'lookup.dart';

class Interactor {
  final _workerClosers = <SendPort>[];
  final _workerPorts = <RawReceivePort>[];
  final _workerDestroyer = ReceivePort();

  late final String? _libraryPath;
  late final InteractorBindings _bindings;
  late final InteractorLibrary _library;

  Interactor({String? libraryPath}) {
    this._libraryPath = libraryPath;
    _library = InteractorLibrary.load(libraryPath: libraryPath);
    _bindings = InteractorBindings(_library.library);
  }

  Future<void> shutdown({Duration? gracefulDuration}) async {
    _workerClosers.forEach((worker) => worker.send(gracefulDuration));
    await _workerDestroyer.take(_workerClosers.length).toList();
    _workerDestroyer.close();
    _workerPorts.forEach((port) => port.close());
  }

  SendPort worker(InteractorWorkerConfiguration configuration) {
    final port = RawReceivePort((ports) async {
      SendPort toWorker = ports[0];
      _workerClosers.add(ports[1]);
      final interactorPointer = calloc<interactor_dart_t>();
      if (interactorPointer == nullptr) throw InteractorInitializationException(InteractorMessages.workerMemoryError);
      final result = using((arena) {
        final nativeConfiguration = arena<interactor_dart_configuration_t>();
        nativeConfiguration.ref.ring_flags = configuration.ringFlags;
        nativeConfiguration.ref.ring_size = configuration.ringSize;
        nativeConfiguration.ref.buffer_size = configuration.bufferSize;
        nativeConfiguration.ref.buffers_count = configuration.buffersCount;
        nativeConfiguration.ref.timeout_checker_period_millis = configuration.timeoutCheckerPeriod.inMilliseconds;
        nativeConfiguration.ref.base_delay_micros = configuration.baseDelay.inMicroseconds;
        nativeConfiguration.ref.max_delay_micros = configuration.maxDelay.inMicroseconds;
        nativeConfiguration.ref.delay_randomization_factor = configuration.delayRandomizationFactor;
        nativeConfiguration.ref.cqe_peek_count = configuration.cqePeekCount;
        nativeConfiguration.ref.cqe_wait_count = configuration.cqeWaitCount;
        nativeConfiguration.ref.cqe_wait_timeout_millis = configuration.cqeWaitTimeout.inMilliseconds;
        nativeConfiguration.ref.slab_size = 65536;
        nativeConfiguration.ref.preallocation_size = 65536;
        nativeConfiguration.ref.quota_size = 128000;
        return _bindings.interactor_dart_initialize(interactorPointer, nativeConfiguration, _workerClosers.length);
      });
      if (result < 0) {
        _bindings.interactor_dart_destroy(interactorPointer);
        throw InteractorInitializationException(InteractorMessages.workerError(result, _bindings));
      }
      final workerInput = [_libraryPath, interactorPointer.address, _workerDestroyer.sendPort, result];
      toWorker.send(workerInput);
    });
    _workerPorts.add(port);
    return port.sendPort;
  }
}
