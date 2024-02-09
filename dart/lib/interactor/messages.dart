import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';

class InteractorMessages {
  final Pointer<interactor_dart_t> _interactor;

  InteractorMessages(this._interactor);

  @pragma(preferInlinePragma)
  Pointer<interactor_message_t> allocate() => interactor_dart_allocate_message(_interactor);

  @pragma(preferInlinePragma)
  void free(Pointer<interactor_message_t> message) => interactor_dart_free_message(_interactor, message);
}
