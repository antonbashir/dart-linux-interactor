import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'buffers.dart';
import 'constants.dart';
import 'data.dart';
import 'payloads.dart';

class InteractorCallDelegate {
  final Completer<InteractorCall> _completer;
  late InteractorCall call;

  InteractorCallDelegate(this._completer);

  @pragma(preferInlinePragma)
  void register(InteractorCall call) => this.call = call;

  @pragma(preferInlinePragma)
  void callback(Pointer<interactor_message> message) {
    call._message = message;
    _completer.complete(call);
  }
}

class InteractorCall {
  Pointer<interactor_message> _message;
  final Pointer<interactor_dart> _interactor;
  final InteractorBindings _bindings;
  final InteractorPayloads _payloads;
  final InteractorBuffers _buffers;
  final InteractorDatas _datas;

  InteractorCall(
    this._message,
    this._interactor,
    this._bindings,
    this._payloads,
    this._buffers,
    this._datas,
    InteractorCallDelegate delegate,
  ) {
    delegate.register(this);
  }

  int get id => _message.ref.id;

  late final int outputSize = _message.ref.output_size;
  late final bool outputBool = _message.ref.output.address == 1;
  late final int outputInt = _message.ref.output.address;
  late final double outputDouble = _message.ref.output.cast<Double>().value;
  late final List<int> outputBuffer = _buffers.read(_message.ref.output.address);
  late final List<int> outputBytes = _message.ref.output.cast<Uint8>().asTypedList(_message.ref.output_size);

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
    Pointer<Double> pointer = _datas.allocate(sizeOf<Double>()).cast();
    pointer.value = data;
    _message.ref.input = pointer.cast();
    _message.ref.input_size = sizeOf<Double>();
  }

  @pragma(preferInlinePragma)
  void setInputString(String data) {
    final units = utf8.encode(data);
    final Pointer<Uint8> result = _datas.allocate(units.length + 1).cast();
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
  void setInputBytes(List<int> bytes) {
    final Pointer<Uint8> pointer = _datas.allocate(bytes.length).cast();
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    _message.ref.input = pointer.cast();
    _message.ref.input_size = bytes.length;
  }

  @pragma(preferInlinePragma)
  void allocateOutputDouble() {
    _message.ref.output = _datas.allocate(sizeOf<Double>()).cast();
    _message.ref.output_size = sizeOf<Double>();
  }

  @pragma(preferInlinePragma)
  void allocateOutputString(int size) {
    final units = empty.padRight(size);
    final Pointer<Uint8> result = _datas.allocate(units.length + 1).cast();
    _message.ref.output = result.cast();
    _message.ref.output_size = units.length + 1;
  }

  Future<void> allocateOutputBuffer(int size) async {
    final bufferId = _buffers.get() ?? await _buffers.allocate();
    _message.ref.output = Pointer.fromAddress(bufferId);
    _message.ref.output_size = size;
  }

  @pragma(preferInlinePragma)
  void allocateOutputBytes(int size) {
    final Pointer<Uint8> pointer = _datas.allocate(size).cast();
    _message.ref.output = pointer.cast();
    _message.ref.output_size = size;
  }

  @pragma(preferInlinePragma)
  String getOutputString({int? length}) => _message.ref.output.cast<Utf8>().toDartString(length: length);

  @pragma(preferInlinePragma)
  Pointer<T> getOutputObject<T extends Struct>() => Pointer.fromAddress(_message.ref.output.address).cast();

  @pragma(preferInlinePragma)
  T parseOutputObject<T, O extends Struct>(T Function(Pointer<O> object) mapper) {
    final object = getOutputObject<O>();
    final result = mapper(object);
    return result;
  }

  @pragma(preferInlinePragma)
  void releaseInputDouble() => _datas.free(_message.ref.input, _message.ref.input_size);

  @pragma(preferInlinePragma)
  void releaseInputString() => _datas.free(_message.ref.input, _message.ref.input_size);

  @pragma(preferInlinePragma)
  void releaseInputObject<T extends Struct>() => _payloads.free(Pointer.fromAddress(_message.ref.input.address).cast<T>());

  @pragma(preferInlinePragma)
  void releaseInputBuffer() => _buffers.release(_message.ref.input.address);

  @pragma(preferInlinePragma)
  void releaseInputBytes() => _datas.free(_message.ref.input, _message.ref.input_size);

  @pragma(preferInlinePragma)
  void releaseOutputDouble() => _datas.free(_message.ref.output, _message.ref.output_size);

  @pragma(preferInlinePragma)
  void releaseOutputString() => _datas.free(_message.ref.output, _message.ref.output_size);

  @pragma(preferInlinePragma)
  void releaseOutputObject<T extends Struct>() => _payloads.free(Pointer.fromAddress(_message.ref.output.address).cast<T>());

  @pragma(preferInlinePragma)
  void releaseOutputBuffer() => _buffers.release(_message.ref.output.address);

  @pragma(preferInlinePragma)
  void releaseOutputBytes() => _datas.free(_message.ref.output, _message.ref.output_size);

  @pragma(preferInlinePragma)
  void release() => _bindings.interactor_dart_free_message(_interactor, _message);
}
