import 'dart:ffi';

import 'bindings.dart';

class NativeFunction {
  final int _id;
  final void Function(Pointer<interactor_message_t> message) _executor;

  NativeFunction(this._id, this._executor);

  void execute(Pointer<interactor_message_t> message) => _executor(message);
}
