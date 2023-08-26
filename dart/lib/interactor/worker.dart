import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:meta/meta.dart';

import 'bindings.dart';
import 'buffers.dart';
import 'constants.dart';
import 'lookup.dart';
import 'payload.dart';
import 'timeout.dart';

class InteractorWorker {
  final _fromInteractor = ReceivePort();

  late final InteractorBindings _bindings;
  late final Pointer<interactor_worker_t> _workerPointer;
  late final Pointer<io_uring> _ring;
  late final Pointer<Pointer<io_uring_cqe>> _cqes;
  late final RawReceivePort _closer;
  late final SendPort _destroyer;
  late final InteractorBuffers _buffers;
  late final InteractorTimeoutChecker _timeoutChecker;
  late final InteractorPayloadPool _payloadPool;
  late final List<Duration> _delays;

  var _active = true;
  final _done = Completer();

  bool get active => _active;
  int get id => _workerPointer.ref.id;
  int get descriptor => _ring.ref.ring_fd;

  InteractorWorker(SendPort toInteractor) {
    _closer = RawReceivePort((gracefulDuration) async {
      _timeoutChecker.stop();
      _active = false;
      await _done.future;
      _bindings.interactor_worker_destroy(_workerPointer);
      _closer.close();
      _destroyer.send(null);
    });
    toInteractor.send([_fromInteractor.sendPort, _closer.sendPort]);
  }

  Future<void> initialize() async {
    final configuration = await _fromInteractor.first as List;
    final libraryPath = configuration[0] as String?;
    _workerPointer = Pointer.fromAddress(configuration[1] as int).cast<interactor_worker_t>();
    _destroyer = configuration[2] as SendPort;
    _fromInteractor.close();
    _bindings = InteractorBindings(InteractorLibrary.load(libraryPath: libraryPath).library);
    _buffers = InteractorBuffers(
      _bindings,
      _workerPointer.ref.buffers,
      _workerPointer,
    );
    _payloadPool = InteractorPayloadPool(_workerPointer.ref.buffers_count, _buffers);
    _ring = _workerPointer.ref.ring;
    _cqes = _workerPointer.ref.cqes;
    _timeoutChecker = InteractorTimeoutChecker(
      _bindings,
      _workerPointer,
      Duration(milliseconds: _workerPointer.ref.timeout_checker_period_millis),
    );
    _delays = _calculateDelays();
    _timeoutChecker.start();
    unawaited(_listen());
  }

  Future<void> _listen() async {
    final baseDelay = _workerPointer.ref.base_delay_micros;
    final regularDelayDuration = Duration(microseconds: baseDelay);
    var attempt = 0;
    while (_active) {
      attempt++;
      if (_handleCqes()) {
        attempt = 0;
        await Future.delayed(regularDelayDuration);
        continue;
      }
      await Future.delayed(_delays[min(attempt, 31)]);
    }
    _done.complete();
  }

  bool _handleCqes() {
    final cqeCount = _bindings.interactor_worker_peek(_workerPointer);
    if (cqeCount == 0) return false;
    for (var cqeIndex = 0; cqeIndex < cqeCount; cqeIndex++) {
      Pointer<io_uring_cqe> cqe = _cqes.elementAt(cqeIndex).value;
      final data = cqe.ref.user_data;
      _bindings.interactor_worker_remove_event(_workerPointer, data);
      final result = cqe.ref.res;
      var event = data & 0xffff;
      final fd = (data >> 32) & 0xffffffff;
      final bufferId = (data >> 16) & 0xffff;
      if (_workerPointer.ref.trace) print(InteractorMessages.workerTrace(id, result, data, fd));

      
    }
    _bindings.interactor_cqe_advance(_ring, cqeCount);
    return true;
  }

  List<Duration> _calculateDelays() {
    final baseDelay = _workerPointer.ref.base_delay_micros;
    final delayRandomizationFactor = _workerPointer.ref.delay_randomization_factor;
    final maxDelay = _workerPointer.ref.max_delay_micros;
    final random = Random();
    final delays = <Duration>[];
    for (var i = 0; i < 32; i++) {
      final randomization = (delayRandomizationFactor * (random.nextDouble() * 2 - 1) + 1);
      final exponent = min(i, 31);
      final delay = (baseDelay * pow(2.0, exponent) * randomization).toInt();
      delays.add(Duration(microseconds: delay < maxDelay ? delay : maxDelay));
    }
    return delays;
  }

  @visibleForTesting
  InteractorBuffers get buffers => _buffers;
}
