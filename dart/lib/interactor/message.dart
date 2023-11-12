import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'buffers.dart';
import 'payloads.dart';

class InteractorCall {
  Pointer<interactor_message> _message;
  final Pointer<interactor_dart> _interactor;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;
  final Completer<InteractorCall> _completer;

  InteractorCall(this._interactor, this._message, this._bindings, this._payloads, this._buffers, this._completer);

  void setInputInt(int data) {
    _message.ref.input = Pointer.fromAddress(data);
    _message.ref.input_size = sizeOf<Int>();
  }

  void setInputBool(bool data) {
    _message.ref.input = Pointer.fromAddress(data ? 1 : 0);
    _message.ref.input_size = sizeOf<Bool>();
  }

  void setInputDouble(double data) {
    Pointer<Double> pointer = Pointer<Double>.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, sizeOf<Double>()));
    pointer.value = data;
    _message.ref.input = pointer.cast();
    _message.ref.input_size = sizeOf<Double>();
  }

  void setInputString(String data) {
    final units = utf8.encode(data);
    final Pointer<Uint8> result = Pointer.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, units.length + 1));
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    _message.ref.input = result.cast();
    _message.ref.input_size = units.length + 1;
  }

  void setInputObject<T extends Struct>(Pointer<T> Function(Pointer<T> object)? configurator) {
    var object = _payloads.allocate<T>();
    if (object == nullptr) throw Exception("TODO: Message");
    object = configurator?.call(object) ?? object;
    _message.ref.input = Pointer.fromAddress(object.address);
    _message.ref.input_size = _payloads.size<T>();
  }

  Future<void> setInputBuffer(List<int> bytes) async {
    final bufferId = _buffers.get() ?? await _buffers.allocate();
    _buffers.write(bufferId, Uint8List.fromList(bytes));
    _message.ref.input = Pointer.fromAddress(bufferId);
    _message.ref.input_size = bytes.length;
  }

  Future<void> setInputBytes(List<int> bytes) async {
    _message.ref.input = Pointer.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, bytes.length));
    _message.ref.input_size = bytes.length;
  }

  void releaseInputDouble() {
    _bindings.interactor_dart_data_free(_interactor, _message.ref.input.address, _message.ref.input_size);
  }

  void releaseInputString() {
    _bindings.interactor_dart_data_free(_interactor, _message.ref.input.address, _message.ref.input_size);
  }

  void releaseInputObject<T extends Struct>() {
    _payloads.free(Pointer.fromAddress(_message.ref.input.address).cast<T>());
  }

  void releaseInputBuffer() {
    _buffers.release(_message.ref.output.address);
  }

  void releaseInputBytes() {
    _bindings.interactor_dart_data_free(_interactor, _message.ref.output.address, _message.ref.output_size);
  }

  void releaseOutputDouble() {
    _bindings.interactor_dart_data_free(_interactor, _message.ref.output.address, _message.ref.output_size);
  }

  void releaseOutputString() {
    _bindings.interactor_dart_data_free(_interactor, _message.ref.output.address, _message.ref.output_size);
  }

  void releaseOutputObject<T extends Struct>() {
    _payloads.free(Pointer.fromAddress(_message.ref.output.address).cast<T>());
  }

  void releaseOutputBuffer() {
    _buffers.release(_message.ref.output.address);
  }

  void releaseOutputBytes() {
    _bindings.interactor_dart_data_free(_interactor, _message.ref.output.address, _message.ref.output_size);
  }

  int getOutputInt() => _message.ref.output.address;

  bool getOutputBool() => _message.ref.output.address == 1;

  double getOutputDouble() {
    Pointer<Double> pointer = _message.ref.output.cast();
    return pointer.value;
  }

  String getOutputString() {
    final Pointer<Utf8> pointer = _message.ref.output.cast();
    return pointer.toDartString();
  }

  Pointer<T> getOutputObject<T extends Struct>() => Pointer.fromAddress(_message.ref.output.address).cast();

  T parseOutputObject<T, O extends Struct>(T Function(Pointer<O> object) mapper) {
    final object = getOutputObject<O>();
    final result = mapper(object);
    return result;
  }

  List<int> getOutputBuffer() => _buffers.read(_message.ref.output.address);

  List<int> getOutputBytes() {
    final Pointer<Uint8> pointer = _message.ref.output.cast();
    return pointer.asTypedList(_message.ref.output_size);
  }

  void callback(Pointer<interactor_message> message) {
    _message = message;
    _completer.complete(this);
  }

  void free() => _bindings.interactor_dart_free_message(_interactor, _message);
}

class InteractorNotification {
  final Pointer<interactor_message> _message;

  InteractorNotification(this._message);

  int getInputInt() => _message.ref.input.address;

  bool getInputBool() => _message.ref.input.address == 1;

  double getInputDouble() {
    Pointer<Double> pointer = _message.ref.input.cast();
    return pointer.value;
  }

  String getInputString() {
    final Pointer<Utf8> pointer = _message.ref.input.cast();
    return pointer.toDartString();
  }

  Pointer<T> getInputObject<T extends Struct>() => Pointer.fromAddress(_message.ref.input.address).cast();

  T parseInputObject<T, O extends Struct>(T Function(Pointer<O> object) mapper) {
    final object = getInputObject<O>();
    final result = mapper(object);
    return result;
  }

  List<int> getInputBytes() {
    final Pointer<Uint8> pointer = _message.ref.input.cast();
    return pointer.asTypedList(_message.ref.input_size);
  }

  void setOutputInt(int data) {
    _message.ref.output = Pointer.fromAddress(data);
  }

  void setOutputBool(bool data) {
    _message.ref.output = Pointer.fromAddress(data ? 1 : 0);
  }

  void setOutputDouble(double data) {
    Pointer<Double> pointer = _message.ref.output.cast();
    _message.ref.input = pointer.cast();
    _message.ref.input_size = sizeOf<Double>();
  }

  void setOutputString(String data) {
    final units = utf8.encode(data);
    final Pointer<Uint8> result = _message.ref.output.cast();
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
  }

  void setOutputObject<T extends Struct>(Pointer<T> Function(Pointer<T> object) configurator) {
    configurator.call(_message.ref.output.cast());
  }

  Future<void> setOutputBytes(List<int> bytes) async {
    final Pointer<Uint8> pointer = _message.ref.output.cast();
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    _message.ref.input_size = bytes.length;
  }
}
