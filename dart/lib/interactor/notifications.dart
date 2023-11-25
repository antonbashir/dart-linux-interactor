import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'constants.dart';

class InteractorNotification {
  final Pointer<interactor_message> _message;

  InteractorNotification(this._message);

  late final int inputSize = _message.ref.input_size;
  late final bool inputBool = _message.ref.input.address == 1;
  late final int inputInt = _message.ref.input.address;
  late final double inputDouble = _message.ref.input.cast<Double>().value;
  late final List<int> inputBytes = _message.ref.input.cast<Uint8>().asTypedList(_message.ref.input_size);

  @pragma(preferInlinePragma)
  String getInputString({int? length}) => _message.ref.input.cast<Utf8>().toDartString(length: length);

  @pragma(preferInlinePragma)
  Pointer<T> getInputObject<T extends Struct>() => Pointer.fromAddress(_message.ref.input.address).cast();

  @pragma(preferInlinePragma)
  T parseInputObject<T, O extends Struct>(T Function(Pointer<O> object) mapper) {
    final object = getInputObject<O>();
    final result = mapper(object);
    return result;
  }

  @pragma(preferInlinePragma)
  void setOutputInt(int data) => _message.ref.output = Pointer.fromAddress(data);

  @pragma(preferInlinePragma)
  void setOutputBool(bool data) => _message.ref.output = Pointer.fromAddress(data ? 1 : 0);

  @pragma(preferInlinePragma)
  void setOutputDouble(double data) {
    Pointer<Double> pointer = _message.ref.output.cast();
    _message.ref.output = pointer.cast();
    _message.ref.output_size = sizeOf<Double>();
  }

  @pragma(preferInlinePragma)
  void setOutputString(String data) {
    final units = utf8.encode(data);
    final Pointer<Uint8> result = _message.ref.output.cast();
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
  }

  @pragma(preferInlinePragma)
  void setOutputObject<T extends Struct>(void Function(Pointer<T> object) configurator) => configurator.call(_message.ref.output.cast());

  @pragma(preferInlinePragma)
  Future<void> setOutputBytes(List<int> bytes) async {
    final Pointer<Uint8> pointer = _message.ref.output.cast();
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    _message.ref.output_size = bytes.length;
  }
}
