import 'dart:ffi';
import 'dart:typed_data';

import 'bindings.dart';
import 'constants.dart';

class InteractorDatas {
  final InteractorBindings _bindings;
  final Pointer<interactor_dart_t> _interactor;

  InteractorDatas(this._bindings, this._interactor);

  late final Finalizer<(int, int)> _dataTupleFinalizer = Finalizer((pointer) => _bindings.interactor_dart_data_free(_interactor, pointer.$1, pointer.$2));

  @pragma(preferInlinePragma)
  Pointer<Void> allocate(int size) => Pointer.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, size));

  @pragma(preferInlinePragma)
  void free(Pointer<Void> pointer, int size) => _bindings.interactor_dart_data_free(_interactor, pointer.address, size);

  @pragma(preferInlinePragma)
  Uint8List allocateDataTuple(int size) {
    final address = _bindings.interactor_dart_data_allocate(_interactor, size);
    final pointer = Pointer<Uint8>.fromAddress(address);
    final tuple = pointer.asTypedList(size);
    _dataTupleFinalizer.attach(tuple, (address, size));
    return tuple;
  }
}
