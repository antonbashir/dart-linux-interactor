import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'bindings.dart';
import 'buffers.dart';
import 'constants.dart';
import 'data.dart';
import 'declaration.dart';
import 'lookup.dart';
import 'payloads.dart';
import 'registry.dart';

class InteractorWorker {
  final _fromInteractor = ReceivePort();

  late final InteractorConsumerRegistry _consumers;
  late final InteractorProducerRegistry _producers;
  late final InteractorPayloads _payloads;
  late final InteractorBuffers _buffers;
  late final InteractorDatas _datas;

  late final InteractorBindings _bindings;
  late final Pointer<interactor_dart_t> _interactor;
  late final Pointer<io_uring> _ring;
  late final int _descriptor;
  late final Pointer<Pointer<io_uring_cqe>> _cqes;
  late final RawReceivePort _closer;
  late final SendPort _destroyer;
  late final List<Duration> _delays;

  var _active = true;
  final _done = Completer();

  bool get active => _active;
  int get id => _interactor.ref.id;
  int get descriptor => _descriptor;
  InteractorPayloads get payloads => _payloads;
  InteractorBuffers get buffers => _buffers;
  InteractorDatas get datas => _datas;

  InteractorWorker(SendPort toInteractor) {
    _closer = RawReceivePort((_) async {
      _active = false;
      await _done.future;
      _payloads.destroy();
      _bindings.interactor_dart_destroy(_interactor);
      _closer.close();
      _destroyer.send(null);
    });
    toInteractor.send([_fromInteractor.sendPort, _closer.sendPort]);
  }

  Future<void> initialize() async {
    final configuration = await _fromInteractor.first as List;
    final libraryPath = configuration[0] as String?;
    _interactor = Pointer.fromAddress(configuration[1] as int).cast<interactor_dart_t>();
    _destroyer = configuration[2] as SendPort;
    _descriptor = configuration[3] as int;
    _fromInteractor.close();
    _bindings = InteractorBindings(InteractorLibrary.load(libraryPath: libraryPath).library);
    _ring = _interactor.ref.ring;
    _cqes = _interactor.ref.cqes;
    _payloads = InteractorPayloads(_bindings, _interactor);
    _buffers = InteractorBuffers(_bindings, _interactor.ref.buffers, _interactor);
    _datas = InteractorDatas(_bindings, _interactor);
    _consumers = InteractorConsumerRegistry(
      _interactor,
      _bindings,
    );
    _producers = InteractorProducerRegistry(
      _interactor,
      _bindings,
      _payloads,
      _buffers,
      _datas,
    );
  }

  void activate() {
    _delays = _calculateDelays();
    unawaited(_listen());
  }

  void consumer(InteractorConsumer declaration) => _consumers.register(declaration);

  T producer<T extends InteractorProducer>(T provider) => _producers.register(provider);

  Future<void> _listen() async {
    final baseDelay = _interactor.ref.base_delay_micros;
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
    final cqeCount = _bindings.interactor_dart_peek(_interactor);
    if (cqeCount == 0) return false;
    for (var cqeIndex = 0; cqeIndex < cqeCount; cqeIndex++) {
      Pointer<io_uring_cqe> cqe = _cqes.elementAt(cqeIndex).value;
      final data = cqe.ref.user_data;
      final result = cqe.ref.res;
      if (result & interactorDartCall > 0) {
        Pointer<interactor_message_t> message = Pointer.fromAddress(data);
        _consumers.call(message);
        continue;
      }
      if (result & interactorDartCallback > 0) {
        Pointer<interactor_message_t> message = Pointer.fromAddress(data);
        _producers.callback(message);
        continue;
      }
    }
    _bindings.interactor_dart_cqe_advance(_ring, cqeCount);
    return true;
  }

  List<Duration> _calculateDelays() {
    final baseDelay = _interactor.ref.base_delay_micros;
    final delayRandomizationFactor = _interactor.ref.delay_randomization_factor;
    final maxDelay = _interactor.ref.max_delay_micros;
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
}
