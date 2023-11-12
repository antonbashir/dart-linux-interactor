import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'messages.dart';

class NativeProducerExecutor {
  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final Map<Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>>, NativeMethodExecutor> _methods = {};

  NativeProducerExecutor(this._id, this._interactorPointer, this._bindings);

  NativeMethodExecutor register(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) {
    _methods[pointer] = NativeMethodExecutor(pointer.address, _id, _interactorPointer, _bindings);
    return _methods[pointer]!;
  }

  void callback(Pointer<interactor_message_t> message) => _methods[message.ref.method]?.callback(message);
}

class NativeMethodExecutor {
  Map<int, InteractorCall> _calls = {};

  final int _methodId;
  final int _executorId;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;

  NativeMethodExecutor(this._methodId, this._executorId, this._interactorPointer, this._bindings);

  Future<InteractorCall> call(int target, {InteractorCall Function(InteractorCall message)? configurator}) {
    final messagePointer = _bindings.interactor_dart_allocate_message(_interactorPointer);
    final completer = Completer<InteractorCall>();
    var message = InteractorCall(_interactorPointer, messagePointer, _bindings, completer);
    if (configurator != null) message = configurator(message);
    messagePointer.ref.id = completer.hashCode;
    messagePointer.ref.source = _interactorPointer.ref.ring.ref.ring_fd;
    messagePointer.ref.owner = _executorId;
    messagePointer.ref.method = _methodId;
    _calls[completer.hashCode] = message;
    _bindings.interactor_dart_call_native(_interactorPointer, target, messagePointer);
    return completer.future.whenComplete(() => _calls.remove(completer.hashCode));
  }

  void callback(Pointer<interactor_message_t> message) => _calls[message.ref.id]?.callback(message);
}
