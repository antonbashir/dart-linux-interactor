import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';
import 'package:ffi/ffi.dart' as ffi;
import 'bindings.dart';
import 'buffers.dart';
import 'constants.dart';
import 'data.dart';
import 'declaration.dart';
import 'messages.dart';
import 'payloads.dart';
import 'registry.dart';
import 'tuples.dart';

class InteractorWorker {
  final _fromInteractor = ReceivePort();

  late final InteractorConsumerRegistry _consumers;
  late final InteractorProducerRegistry _producers;
  late final InteractorPayloads _payloads;
  late final InteractorStaticBuffers _staticBuffers;
  late final InteractorInputOutputBuffers _ioBuffers;
  late final InteractorDatas _datas;
  late final InteractorMessages _messages;
  late final InteractorTuples _tuples;

  late final Pointer<interactor_dart> _interactor;
  late final int _descriptor;
  late final Pointer<Pointer<interactor_dart_completion_event>> _completions;
  late final RawReceivePort _closer;
  late final SendPort _destroyer;
  late final List<Duration> _delays;

  var _active = false;
  final _done = Completer();

  bool get active => _active;
  int get id => _interactor.ref.id;
  int get descriptor => _descriptor;
  InteractorPayloads get payloads => _payloads;
  InteractorStaticBuffers get staticBuffers => _staticBuffers;
  InteractorInputOutputBuffers get inputOutputBuffers => _ioBuffers;
  InteractorDatas get datas => _datas;
  InteractorMessages get messages => _messages;
  InteractorTuples get tuples => _tuples;
  Pointer<interactor_memory> get memory => _interactor.ref.memory;

  InteractorWorker(SendPort toInteractor) {
    _closer = RawReceivePort((_) async {
      await deactivate();
      _payloads.destroy();
      interactor_dart_destroy(_interactor);
      ffi.calloc.free(_interactor);
      _closer.close();
      _destroyer.send(null);
    });
    toInteractor.send([_fromInteractor.sendPort, _closer.sendPort]);
  }

  Future<void> initialize() async {
    final configuration = await _fromInteractor.first as List;
    _interactor = Pointer.fromAddress(configuration[0] as int).cast<interactor_dart>();
    _destroyer = configuration[1] as SendPort;
    _descriptor = configuration[2] as int;
    _fromInteractor.close();
    _completions = _interactor.ref.completions;
    _payloads = InteractorPayloads(_interactor);
    _staticBuffers = InteractorStaticBuffers(interactor_dart_static_buffers_inner(_interactor), _interactor);
    _ioBuffers = InteractorInputOutputBuffers(_interactor);
    _datas = InteractorDatas(_interactor);
    _messages = InteractorMessages(_interactor);
    _tuples = InteractorTuples(_interactor);
    _consumers = InteractorConsumerRegistry(_interactor);
    _producers = InteractorProducerRegistry(_interactor);
  }

  void activate() {
    _active = true;
    _delays = _calculateDelays();
    unawaited(_listen());
  }

  Future<void> deactivate() async {
    if (_active) {
      _active = false;
      await _done.future;
    }
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
    final cqeCount = interactor_dart_peek(_interactor);
    if (cqeCount == 0) return false;
    for (var cqeIndex = 0; cqeIndex < cqeCount; cqeIndex++) {
      Pointer<interactor_completion_event> cqe = _completions.elementAt(cqeIndex).value.cast();
      final data = cqe.ref.user_data;
      final result = cqe.ref.res;
      print("data: ${data}");
      print("result: ${result}");
      if (data > 0) {
        if (result & interactorDartCall > 0) {
          Pointer<interactor_message> message = Pointer.fromAddress(data);
          _consumers.call(message);
          continue;
        }
        if (result & interactorDartCallback > 0) {
          Pointer<interactor_message> message = Pointer.fromAddress(data);
          _producers.callback(message);
          continue;
        }

        continue;
      }
    }
    interactor_dart_cqe_advance(_interactor, cqeCount);
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
