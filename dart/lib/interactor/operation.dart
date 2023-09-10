import 'dart:ffi';

import 'bindings.dart';

class InteractorOperation {
  final int _id;
  final void Function(Pointer<interactor_message_t> message) _executor;

  InteractorOperation(this._id, this._executor);

  void execute(Pointer<interactor_message_t> message) => _executor(message);
}
