import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'buffers.dart';
import 'constants.dart';
import 'message.dart';
import 'payloads.dart';

class NativeProducerExecutor {
  final Map<int, NativeMethodExecutor> _methods = {};

  final int _id;
  final Pointer<interactor_dart_t> _interactorPointer;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;

  NativeProducerExecutor(this._id, this._interactorPointer, this._bindings, this._payloads, this._buffers);

  @pragma(preferInlinePragma)
  NativeMethodExecutor register(Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> pointer) {
    final executor = NativeMethodExecutor(pointer.address, _id, _interactorPointer, _bindings, _payloads, _buffers);
    _methods[pointer.address] = executor;
    return executor;
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _methods[message.ref.method]?.callback(message);
}

class NativeMethodExecutor {
  Map<int, InteractorCall> _calls = {};

  final int _methodId;
  final int _executorId;
  final Pointer<interactor_dart_t> _interactor;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;

  NativeMethodExecutor(this._methodId, this._executorId, this._interactor, this._bindings, this._payloads, this._buffers);

  @pragma(preferInlinePragma)
  Future<InteractorCall> call(int target, {InteractorCall Function(InteractorCall message)? configurator, Duration? timeout}) {
    final messagePointer = _bindings.interactor_dart_allocate_message(_interactor);
    final completer = Completer<InteractorCall>();
    var message = InteractorCall(_interactor, messagePointer, _bindings, _payloads, _buffers, completer);
    message = configurator?.call(message) ?? message;
    messagePointer.ref.id = completer.hashCode;
    messagePointer.ref.owner = _executorId;
    messagePointer.ref.method = _methodId;
    _calls[completer.hashCode] = message;
    _bindings.interactor_dart_call_native(_interactor, target, messagePointer, timeout?.inMilliseconds ?? interactorTimeoutInfinity);
    return completer.future.whenComplete(() => _calls.remove(completer.hashCode));
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _calls[message.ref.id]?.callback(message);
}
