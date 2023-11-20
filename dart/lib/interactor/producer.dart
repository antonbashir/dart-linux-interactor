import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'calls.dart';
import 'constants.dart';
import 'data.dart';
import 'payloads.dart';

class NativeProducerExecutor {
  final Map<int, NativeMethodExecutor> _methods = {};

  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;
  final InteractorDatas _datas;

  NativeProducerExecutor(
    this._id,
    this._interactorPointer,
    this._bindings,
    this._payloads,
    this._buffers,
    this._datas,
  );

  @pragma(preferInlinePragma)
  NativeMethodExecutor register(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) {
    final executor = NativeMethodExecutor(
      pointer.address,
      _id,
      _interactorPointer,
      _bindings,
      _payloads,
      _buffers,
      _datas,
    );
    _methods[pointer.address] = executor;
    return executor;
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _methods[message.ref.method]?.callback(message);
}

class NativeMethodExecutor {
  Map<int, InteractorCallDelegate> _calls = {};

  final int _methodId;
  final int _executorId;
  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;
  final InteractorDatas _datas;

  var _nextId = 0;
  int get nextId {
    if (_nextId == intMaxValue - 1) {
      _nextId = 0;
      return 0;
    }
    return ++_nextId;
  }

  NativeMethodExecutor(
    this._methodId,
    this._executorId,
    this._interactor,
    this._bindings,
    this._payloads,
    this._buffers,
    this._datas,
  );

  @pragma(preferInlinePragma)
  Future<InteractorCall> call(int target, {FutureOr<void> Function(InteractorCall message)? configurator, Duration? timeout}) {
    final message = _bindings.interactor_dart_allocate_message(_interactor);
    final completer = Completer<InteractorCall>();
    final delegate = InteractorCallDelegate(
      completer,
    );
    var call = InteractorCall(
      message,
      _interactor,
      _bindings,
      _payloads,
      _buffers,
      _datas,
      delegate,
    );
    if (configurator == null) {
      message.ref.id = nextId;
      message.ref.owner = _executorId;
      message.ref.method = _methodId;
      _calls[_nextId] = delegate;
      _bindings.interactor_dart_call_native(_interactor, target, message, timeout?.inMilliseconds ?? interactorTimeoutInfinity);
      return completer.future.then((message) {
        _calls.remove(message.id);
        return message;
      });
    }
    return Future.value(configurator.call(call)).then((call) {
      message.ref.id = nextId;
      message.ref.owner = _executorId;
      message.ref.method = _methodId;
      _calls[_nextId] = delegate;
      _bindings.interactor_dart_call_native(_interactor, target, message, timeout?.inMilliseconds ?? interactorTimeoutInfinity);
      return completer.future.then((message) {
        _calls.remove(message.id);
        return message;
      });
    });
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _calls[message.ref.id]?.callback(message);
}
