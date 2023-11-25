import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'calls.dart';
import 'constants.dart';
import 'data.dart';
import 'declaration.dart';
import 'exception.dart';
import 'payloads.dart';

class InteractorProducerExecutor implements InteractorProducerRegistrat {
  final Map<int, InteractorMethodExecutor> _methods = {};

  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;
  final InteractorDatas _datas;

  InteractorProducerExecutor(
    this._id,
    this._interactorPointer,
    this._bindings,
    this._payloads,
    this._buffers,
    this._datas,
  );

  InteractorMethod register(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) {
    final executor = InteractorMethodExecutor(
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

class InteractorMethodExecutor implements InteractorMethod {
  Map<int, InteractorCallDelegate> _calls = {};

  final int _methodId;
  final int _executorId;
  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;
  final InteractorDatas _datas;

  var _nextId = 0;
  int? get nextId {
    if (_nextId == intMaxValue) _nextId = 0;
    while (_calls.containsKey(++_nextId)) {
      if (_nextId == intMaxValue) {
        _nextId = 0;
        return null;
      }
    }
    return _nextId;
  }

  InteractorMethodExecutor(
    this._methodId,
    this._executorId,
    this._interactor,
    this._bindings,
    this._payloads,
    this._buffers,
    this._datas,
  );

  @override
  @pragma(preferInlinePragma)
  Future<InteractorCall> call(int target, {FutureOr<void> Function(InteractorCall message)? configurator}) {
    final message = _bindings.interactor_dart_allocate_message(_interactor);
    final completer = Completer<InteractorCall>();
    final delegate = InteractorCallDelegate(completer);
    final call = InteractorCall(
      message,
      _interactor,
      _bindings,
      _payloads,
      _buffers,
      _datas,
      delegate,
    );
    if (configurator == null) {
      final id = nextId;
      if (id == null) throw InteractorRuntimeException(InteractorMessages.interactorLimitError);
      message.ref.id = id;
      message.ref.owner = _executorId;
      message.ref.method = _methodId;
      _calls[id] = delegate;
      _bindings.interactor_dart_call_native(_interactor, target, message);
      return completer.future.whenComplete(() => _calls.remove(id));
    }
    return Future.value(configurator..call(call)).then((call) {
      final id = nextId;
      if (id == null) throw InteractorRuntimeException(InteractorMessages.interactorLimitError);
      message.ref.id = id;
      message.ref.owner = _executorId;
      message.ref.method = _methodId;
      _calls[id] = delegate;
      _bindings.interactor_dart_call_native(_interactor, target, message);
      return completer.future.whenComplete(() => _calls.remove(id));
    });
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _calls[message.ref.id]?.callback(message);
}
