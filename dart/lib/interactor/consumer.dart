import 'dart:async';
import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';

class InteractorConsumerExecutor {
  final List<InteractorCallbackExecutor> _callbacks;

  InteractorConsumerExecutor(this._callbacks);

  @pragma(preferInlinePragma)
  void call(Pointer<interactor_message> message) => _callbacks[message.ref.method].call(message);
}

class InteractorCallbackExecutor {
  final Pointer<interactor_dart> _interactor;
  final FutureOr<void> Function(Pointer<interactor_message> notification) _executor;

  InteractorCallbackExecutor(this._interactor, this._executor);

  @pragma(preferInlinePragma)
  void call(Pointer<interactor_message> message) => Future.value(_executor(message)).then((_) => interactor_dart_callback_to_native(_interactor, message));
}
