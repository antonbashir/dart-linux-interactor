import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'messages.dart';

class NativeProducerExecutor {
  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;
  final Map<Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>>, NativeMethodExecutor> _methods = {};

  NativeProducerExecutor(this._id, this._interactorPointer, this._bindings, this._buffers);

  NativeMethodExecutor register(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) {
    _methods[pointer] = NativeMethodExecutor(pointer.address, _id, _interactorPointer, _bindings, _buffers);
    return _methods[pointer]!;
  }

  void callback(Pointer<interactor_message_t> message) => _methods[message.ref.method]?.callback(message);
}

class NativeMethodExecutor {
  final int _methodId;
  final int _executorId;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorBuffers _buffers;

  Map<int, InteractorMessage> _messages = {};

  NativeMethodExecutor(this._methodId, this._executorId, this._interactorPointer, this._bindings, this._buffers);

  Future<InteractorMessage> call(int target, {InteractorMessage Function(InteractorMessage message)? configurator}) {
    final messagePointer = _bindings.interactor_dart_allocate_message(_interactorPointer);
    final completer = Completer<InteractorMessage>();
    var message = InteractorMessage(_interactorPointer, messagePointer, _bindings, completer);
    if (configurator != null) message = configurator(message);
    messagePointer.ref.id = completer.hashCode;
    messagePointer.ref.source = _interactorPointer.ref.ring.ref.ring_fd;
    messagePointer.ref.owner = _executorId;
    messagePointer.ref.method = _methodId;
    _messages[completer.hashCode] = message;
    _bindings.interactor_dart_call_native(_interactorPointer, target, messagePointer);
    return completer.future.whenComplete(() => _messages.remove(completer.hashCode));
  }

  void callback(Pointer<interactor_message_t> message) => _messages[message.ref.id]?.callback(message);
}
