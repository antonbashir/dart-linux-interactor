import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';

class InteractorDatas {
  final Pointer<interactor_dart_t> _interactor;

  InteractorDatas(this._interactor);

  @pragma(preferInlinePragma)
  Pointer<Void> allocate(int size) => Pointer.fromAddress(interactor_dart_data_allocate(_interactor, size));

  @pragma(preferInlinePragma)
  void free(Pointer<Void> pointer, int size) => interactor_dart_data_free(_interactor, pointer.address, size);
}
