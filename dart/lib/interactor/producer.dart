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
  Future<InteractorCall> call(int target, {InteractorCall Function(InteractorCall message)? configurator, Duration? timeout}) {
    final messagePointer = _bindings.interactor_dart_allocate_message(_interactor);
    final completer = Completer<InteractorCall>();
    final delegate = InteractorCallDelegate(
      completer,
    );
    var call = InteractorCall(
      _interactor,
      _bindings,
      _payloads,
      _buffers,
      _datas,
      delegate,
    );
    call = configurator?.call(call) ?? call;
    messagePointer.ref.id = completer.hashCode;
    messagePointer.ref.owner = _executorId;
    messagePointer.ref.method = _methodId;
    _calls[completer.hashCode] = delegate;
    _bindings.interactor_dart_call_native(_interactor, target, messagePointer, timeout?.inMilliseconds ?? interactorTimeoutInfinity);
    return completer.future.whenComplete(() => _calls.remove(completer.hashCode));
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message_t> message) => _calls[message.ref.id]?.callback(message);
}
