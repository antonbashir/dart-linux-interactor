import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'buffers.dart';
import 'constants.dart';
import 'payloads.dart';

class InteractorCall {
  Pointer<interactor_message> _message;
  final Pointer<interactor_dart> _interactor;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;
  final Completer<InteractorCall> _completer;

  InteractorCall(
    this._interactor,
    this._message,
    this._bindings,
    this._payloads,
    this._buffers,
    this._completer,
  );

  @pragma(preferInlinePragma)
  void setInputInt(int data) {
    _message.ref.input = Pointer.fromAddress(data);
    _message.ref.input_size = sizeOf<Int>();
  }

  @pragma(preferInlinePragma)
  void setInputBool(bool data) {
    _message.ref.input = Pointer.fromAddress(data ? 1 : 0);
    _message.ref.input_size = sizeOf<Bool>();
  }

  @pragma(preferInlinePragma)
  void setInputDouble(double data) {
    Pointer<Double> pointer = Pointer<Double>.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, sizeOf<Double>()));
    pointer.value = data;
    _message.ref.input = pointer.cast();
    _message.ref.input_size = sizeOf<Double>();
  }

  @pragma(preferInlinePragma)
  void setInputString(String data) {
    final units = utf8.encode(data);
    final Pointer<Uint8> result = Pointer.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, units.length + 1));
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    _message.ref.input = result.cast();
    _message.ref.input_size = units.length + 1;
  }

  @pragma(preferInlinePragma)
  void setInputObject<T extends Struct>(void Function(Pointer<T> object)? configurator) {
    var object = _payloads.allocate<T>();
    configurator?.call(object);
    _message.ref.input = Pointer.fromAddress(object.address);
    _message.ref.input_size = _payloads.size<T>();
  }

  @pragma(preferInlinePragma)
  Future<void> setInputBuffer(List<int> bytes) async {
    final bufferId = _buffers.get() ?? await _buffers.allocate();
    _buffers.write(bufferId, Uint8List.fromList(bytes));
    _message.ref.input = Pointer.fromAddress(bufferId);
    _message.ref.input_size = bytes.length;
  }

  @pragma(preferInlinePragma)
  Future<void> setInputBytes(List<int> bytes) async {
    final Pointer<Uint8> pointer = Pointer.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, bytes.length));
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    _message.ref.input = pointer.cast();
    _message.ref.input_size = bytes.length;
  }

  @pragma(preferInlinePragma)
  void releaseInputDouble() => _bindings.interactor_dart_data_free(_interactor, _message.ref.input.address, _message.ref.input_size);

  @pragma(preferInlinePragma)
  void releaseInputString() => _bindings.interactor_dart_data_free(_interactor, _message.ref.input.address, _message.ref.input_size);

  @pragma(preferInlinePragma)
  void releaseInputObject<T extends Struct>() => _payloads.free(Pointer.fromAddress(_message.ref.input.address).cast<T>());

  @pragma(preferInlinePragma)
  void releaseInputBuffer() => _buffers.release(_message.ref.input.address);

  @pragma(preferInlinePragma)
  void releaseInputBytes() => _bindings.interactor_dart_data_free(_interactor, _message.ref.input.address, _message.ref.input_size);

  @pragma(preferInlinePragma)
  void releaseOutputDouble() => _bindings.interactor_dart_data_free(_interactor, _message.ref.output.address, _message.ref.output_size);

  @pragma(preferInlinePragma)
  void releaseOutputString() => _bindings.interactor_dart_data_free(_interactor, _message.ref.output.address, _message.ref.output_size);

  @pragma(preferInlinePragma)
  void releaseOutputObject<T extends Struct>() => _payloads.free(Pointer.fromAddress(_message.ref.output.address).cast<T>());

  @pragma(preferInlinePragma)
  void releaseOutputBuffer() => _buffers.release(_message.ref.output.address);

  @pragma(preferInlinePragma)
  void releaseOutputBytes() => _bindings.interactor_dart_data_free(_interactor, _message.ref.output.address, _message.ref.output_size);

  late final bool outputBool = _message.ref.output.address == 1;
  late final int outputInt = _message.ref.output.address;
  late final double outputDouble = _message.ref.output.cast<Double>().value;
  late final String outputString = _message.ref.output.cast<Utf8>().toDartString();
  late final List<int> outputBuffer = _buffers.read(_message.ref.output.address);
  late final List<int> outputBytes = _message.ref.output.cast<Uint8>().asTypedList(_message.ref.output_size);

  @pragma(preferInlinePragma)
  Pointer<T> getOutputObject<T extends Struct>() => Pointer.fromAddress(_message.ref.output.address).cast();

  @pragma(preferInlinePragma)
  T parseOutputObject<T, O extends Struct>(T Function(Pointer<O> object) mapper) {
    final object = getOutputObject<O>();
    final result = mapper(object);
    return result;
  }

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message> message) {
    _message = message;
    _completer.complete(this);
  }

  @pragma(preferInlinePragma)
  void release() => _bindings.interactor_dart_free_message(_interactor, _message);
}

class InteractorNotification {
  final Pointer<interactor_message> _message;

  InteractorNotification(this._message);

  late final bool inputBool = _message.ref.input.address == 1;
  late final int inputInt = _message.ref.input.address;
  late final double inputDouble = _message.ref.input.cast<Double>().value;
  late final String inputString = _message.ref.input.cast<Utf8>().toDartString();
  late final List<int> inputBytes = _message.ref.input.cast<Uint8>().asTypedList(_message.ref.output_size);

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
