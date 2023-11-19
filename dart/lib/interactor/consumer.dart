import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';
import 'notifications.dart';

class NativeConsumerExecutor {
  final List<NativeCallbackExecutor> _callbacks;

  NativeConsumerExecutor(this._callbacks);

  @pragma(preferInlinePragma)
  void call(Pointer<interactor_message_t> message) => _callbacks[message.ref.method].call(message);
}

class NativeCallbackExecutor {
  final InteractorBindings _bindings;
  final Pointer<interactor_dart_t> _interactor;
  final FutureOr<void> Function(InteractorNotification notification) _executor;

  NativeCallbackExecutor(this._bindings, this._interactor, this._executor);

  @pragma(preferInlinePragma)
  void call(Pointer<interactor_message_t> message) => Future.value(_executor(InteractorNotification(message))).whenComplete(() => _bindings.interactor_dart_callback_to_native(_interactor, message));
}
