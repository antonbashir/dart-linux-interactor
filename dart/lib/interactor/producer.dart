import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';
import 'declaration.dart';
import 'exception.dart';

class InteractorProducerExecutor implements InteractorProducerRegistrat {
  final Map<int, InteractorMethodExecutor> _methods = {};

  final int _id;
  final Pointer<interactor_dart> _interactorPointer;

  InteractorProducerExecutor(this._id, this._interactorPointer);

  InteractorMethod register(Pointer<NativeFunction<Void Function(Pointer<interactor_message>)>> pointer) {
    final executor = InteractorMethodExecutor(pointer.address, _id, _interactorPointer);
    _methods[pointer.address] = executor;
    return executor;
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message> message) => _methods[message.ref.method]?.callback(message);
}

class InteractorMethodExecutor implements InteractorMethod {
  final Map<int, Completer<Pointer<interactor_message>>> _calls = {};
  final int _methodId;
  final int _executorId;
  final Pointer<interactor_dart> _interactor;

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
  );

  @override
  @pragma(preferInlinePragma)
  Future<Pointer<interactor_message>> call(int target, Pointer<interactor_message> message) {
    final completer = Completer<Pointer<interactor_message>>();
    final id;
    if ((id = nextId) == null) throw InteractorRuntimeException(InteractorErrors.interactorLimitError);
    message.ref.id = id;
    message.ref.owner = _executorId;
    message.ref.method = _methodId;
    _calls[id] = completer;
    interactor_dart_call_native(_interactor, target, message);
    return completer.future.whenComplete(() => _calls.remove(id));
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message> message) => _calls[message.ref.id]?.complete(message);
}
