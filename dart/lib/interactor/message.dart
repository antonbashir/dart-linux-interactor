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

extension InteractorMessageExtensions on Pointer<interactor_message> {
  @pragma(preferInlinePragma)
  int get id => ref.id;

  @pragma(preferInlinePragma)
  Pointer<Void> get inputPointer => ref.input;

  @pragma(preferInlinePragma)
  int get inputSize => ref.input_size;

  @pragma(preferInlinePragma)
  bool get inputBool => ref.input.address == 1;

  @pragma(preferInlinePragma)
  int get inputInt => ref.input.address;

  @pragma(preferInlinePragma)
  double get inputDouble => ref.input.cast<Double>().value;

  @pragma(preferInlinePragma)
  Uint8List get inputBytes => ref.input.cast<Uint8>().asTypedList(ref.input_size);

  @pragma(preferInlinePragma)
  List<int> getOutputStaticBuffer(InteractorStaticBuffers buffers) => buffers.read(ref.output.address);

  @pragma(preferInlinePragma)
  List<int> getInputStaticBuffer(InteractorStaticBuffers buffers) => buffers.read(ref.input.address);

  @pragma(preferInlinePragma)
  String getInputString({int? length}) => ref.input.cast<Utf8>().toDartString(length: length);

  @pragma(preferInlinePragma)
  Pointer<T> getInputObject<T extends Struct>() => Pointer.fromAddress(ref.input.address).cast();

  @pragma(preferInlinePragma)
  T parseInputObject<T, O extends Struct>(T Function(Pointer<O> object) mapper) => mapper(getInputObject<O>());

  @pragma(preferInlinePragma)
  void setInputInt(int data) {
    ref.input = Pointer.fromAddress(data);
    ref.input_size = sizeOf<Int>();
  }

  @pragma(preferInlinePragma)
  void setInputBool(bool data) {
    ref.input = Pointer.fromAddress(data ? 1 : 0);
    ref.input_size = sizeOf<Bool>();
  }

  @pragma(preferInlinePragma)
  void setInputDouble(InteractorDatas datas, double data) {
    Pointer<Double> pointer = datas.allocate(sizeOf<Double>()).cast();
    pointer.value = data;
    ref.input = pointer.cast();
    ref.input_size = sizeOf<Double>();
  }

  @pragma(preferInlinePragma)
  void setInputString(InteractorDatas datas, String data) {
    final units = utf8.encode(data);
    final Pointer<Uint8> result = datas.allocate(units.length + 1).cast();
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    ref.input = result.cast();
    ref.input_size = units.length + 1;
  }

  @pragma(preferInlinePragma)
  void setInputObject<T extends Struct>(InteractorPayloads payloads, void Function(Pointer<T> object)? configurator) {
    var object = payloads.allocate<T>();
    configurator?.call(object);
    ref.input = Pointer.fromAddress(object.address);
    ref.input_size = payloads.size<T>();
  }

  @pragma(preferInlinePragma)
  Future<void> setInputStaticBuffer(InteractorStaticBuffers buffers, List<int> bytes) async {
    final bufferId = buffers.get() ?? await buffers.allocate();
    buffers.write(bufferId, Uint8List.fromList(bytes));
    ref.input = Pointer.fromAddress(bufferId);
    ref.input_size = bytes.length;
  }

  @pragma(preferInlinePragma)
  void setInputBytes(InteractorDatas datas, List<int> bytes) {
    final Pointer<Uint8> pointer = datas.allocate(bytes.length).cast();
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    ref.input = pointer.cast();
    ref.input_size = bytes.length;
  }

  @pragma(preferInlinePragma)
  void freeInputDouble(InteractorDatas datas) => datas.free(ref.input, ref.input_size);

  @pragma(preferInlinePragma)
  void freeInputString(InteractorDatas datas) => datas.free(ref.input, ref.input_size);

  @pragma(preferInlinePragma)
  void freeInputObject<T extends Struct>(InteractorPayloads payloads) => payloads.free(Pointer.fromAddress(ref.input.address).cast<T>());

  @pragma(preferInlinePragma)
  void releaseInputStaticBuffer(InteractorStaticBuffers buffers) => buffers.release(ref.input.address);

  @pragma(preferInlinePragma)
  void freeInputBytes(InteractorDatas datas) => datas.free(ref.input, ref.input_size);

  @pragma(preferInlinePragma)
  int get outputSize => ref.output_size;

  @pragma(preferInlinePragma)
  Pointer<Void> get outputPointer => ref.output;

  @pragma(preferInlinePragma)
  bool get outputBool => ref.output.address == 1;

  @pragma(preferInlinePragma)
  int get outputInt => ref.output.address;

  @pragma(preferInlinePragma)
  double get outputDouble => ref.output.cast<Double>().value;

  @pragma(preferInlinePragma)
  Uint8List get outputBytes => ref.output.cast<Uint8>().asTypedList(ref.output_size);

  @pragma(preferInlinePragma)
  void allocateOutputDouble(InteractorDatas datas) {
    ref.output = datas.allocate(sizeOf<Double>()).cast();
    ref.output_size = sizeOf<Double>();
  }

  @pragma(preferInlinePragma)
  void allocateOutputString(int size, InteractorDatas datas) {
    final units = empty.padRight(size);
    final Pointer<Uint8> result = datas.allocate(units.length + 1).cast();
    ref.output = result.cast();
    ref.output_size = units.length + 1;
  }

  Future<void> allocateOutputStaticBuffer(InteractorStaticBuffers buffers, int size) async {
    final bufferId = buffers.get() ?? await buffers.allocate();
    ref.output = Pointer.fromAddress(bufferId);
    ref.output_size = size;
  }

  @pragma(preferInlinePragma)
  void allocateOutputBytes(InteractorDatas datas, int size) {
    final Pointer<Uint8> pointer = datas.allocate(size).cast();
    ref.output = pointer.cast();
    ref.output_size = size;
  }

  @pragma(preferInlinePragma)
  String getOutputString({int? length}) => ref.output.cast<Utf8>().toDartString(length: length);

  @pragma(preferInlinePragma)
  Pointer<T> getOutputObject<T extends Struct>() => Pointer.fromAddress(ref.output.address).cast();

  @pragma(preferInlinePragma)
  T parseOutputObject<T, O extends Struct>(T Function(Pointer<O> object) mapper) => mapper(getOutputObject<O>());

  @pragma(preferInlinePragma)
  void freeOutputDouble(InteractorDatas datas) => datas.free(ref.output, ref.output_size);

  @pragma(preferInlinePragma)
  void freeOutputString(InteractorDatas datas) => datas.free(ref.output, ref.output_size);

  @pragma(preferInlinePragma)
  void freeOutputObject<T extends Struct>(InteractorPayloads payloads) => payloads.free(Pointer.fromAddress(ref.output.address).cast<T>());

  @pragma(preferInlinePragma)
  void releaseOutputStaticBuffer(InteractorStaticBuffers buffers) => buffers.release(ref.output.address);

  @pragma(preferInlinePragma)
  void freeOutputBytes(InteractorDatas datas) => datas.free(ref.output, ref.output_size);
}
