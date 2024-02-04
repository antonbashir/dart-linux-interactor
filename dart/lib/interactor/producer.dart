import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';
import 'declaration.dart';
import 'exception.dart';

class InteractorProducerExecutor implements InteractorProducerRegistrat {
  final Map<int, InteractorMethodExecutor> _methods = {};

  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;

  InteractorProducerExecutor(
    this._id,
    this._interactorPointer,
    this._bindings,
  );

  InteractorMethod register(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) {
    final executor = InteractorMethodExecutor(
      pointer.address,
      _id,
      _interactorPointer,
      _bindings,
    );
    _methods[pointer.address] = executor;
    return executor;
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _methods[message.ref.method]?.callback(message);
}

class InteractorMethodExecutor implements InteractorMethod {
  final Map<int, Completer<Pointer<interactor_message_t>>> _calls = {};
  final int _methodId;
  final int _executorId;
  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;

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
  );

  @override
  @pragma(preferInlinePragma)
  Future<Pointer<interactor_message_t>> call(int target, Pointer<interactor_message_t> message) {
    final completer = Completer<Pointer<interactor_message_t>>();
    final id;
    if ((id = nextId) == null) throw InteractorRuntimeException(InteractorErrors.interactorLimitError);
    message.ref.id = id;
    message.ref.owner = _executorId;
    message.ref.method = _methodId;
    _calls[id] = completer;
    _bindings.interactor_dart_call_native(_interactor, target, message);
    return completer.future.whenComplete(() => _calls.remove(id));
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _calls[message.ref.id]?.complete(message);
}
