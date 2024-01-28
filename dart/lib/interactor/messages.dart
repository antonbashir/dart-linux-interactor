import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';

class InteractorMessages {
  final InteractorBindings _bindings;
  final Pointer<interactor_dart_t> _interactor;

  InteractorMessages(this._bindings, this._interactor);

  @pragma(preferInlinePragma)
  Pointer<interactor_message_t> allocate() => _bindings.interactor_dart_allocate_message(_interactor);

  @pragma(preferInlinePragma)
  void free(Pointer<interactor_message_t> message) => _bindings.interactor_dart_free_message(_interactor, message);
}
