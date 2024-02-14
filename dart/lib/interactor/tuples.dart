import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'bindings.dart';
import 'constants.dart';
import 'extensions.dart';

const tupleSizeOfNull = 1;
const tupleSizeOfBool = 1;
const tupleSizeOfDouble = 9;

const _decoder = const Utf8Decoder();

@pragma(preferInlinePragma)
int tupleWriteNull(ByteData data, int offset) {
  data.setUint8(offset++, 0xc0);
  return offset;
}

@pragma(preferInlinePragma)
int tupleWriteBool(ByteData data, bool value, int offset) {
  data.setUint8(offset++, value ? 0xc3 : 0xc2);
  return offset;
}

@pragma(preferInlinePragma)
int tupleWriteInt(ByteData data, int value, int offset) {
  if (value >= 0) {
    if (value <= 0x7f) {
      data.setUint8(offset++, value);
      return offset;
    }
    if (value <= 0xFF) {
      data.setUint8(offset++, 0xcc);
      data.setUint8(offset++, value);
    }
    if (value <= 0xFFFF) {
      data.setUint8(offset++, 0xcd);
      data.setUint16(offset, value);
      return offset + 2;
    }
    if (value <= 0xFFFFFFFF) {
      data.setUint8(offset++, 0xce);
      data.setUint32(offset, value);
      return offset + 4;
    }
    data.setUint8(offset++, 0xcf);
    data.setUint64(offset, value);
    return offset + 8;
  }
  if (value >= -0x20) {
    data.setUint8(offset++, value);
    return offset;
  }
  if (value >= -128) {
    data.setUint8(offset++, 0xd0);
    data.setInt8(offset++, value);
    return offset;
  }
  if (value >= -32768) {
    data.setUint8(offset++, 0xd1);
    data.setInt16(offset, value);
    return offset + 2;
  }
  if (value >= -2147483648) {
    data.setUint8(offset++, 0xd2);
    data.setInt32(offset, value);
    return offset + 4;
  }
  data.setUint8(offset++, 0xd3);
  data.setInt64(offset, value);
  return offset + 8;
}

@pragma(preferInlinePragma)
int tupleWriteDouble(ByteData data, double value, int offset) {
  data.setUint8(offset++, 0xcb);
  data.setFloat64(offset, value);
  return offset + 8;
}

@pragma(preferInlinePragma)
int tupleWriteString(Uint8List buffer, ByteData data, String value, int offset) {
  final length = value.length;
  if (length <= 0x1F) {
    data.setUint8(offset++, 0xA0 | length);
    fastEncodeString(value, buffer, offset);
    return offset + length;
  }
  if (length <= 0xFF) {
    data.setUint8(offset++, 0xd9);
    data.setUint8(offset++, length);
    fastEncodeString(value, buffer, offset);
    return offset + length;
  }
  if (length <= 0xFFFF) {
    data.setUint8(offset++, 0xda);
    data.setUint16(offset, length);
    offset += 2;
    fastEncodeString(value, buffer, offset);
    return offset + length;
  }
  if (length <= 0xFFFFFFFF) {
    data.setUint8(offset++, 0xdb);
    data.setUint32(offset, length);
    offset += 4;
    fastEncodeString(value, buffer, offset);
    return offset + length;
  }
  throw ArgumentError('Max string length is 0xFFFFFFFF');
}

@pragma(preferInlinePragma)
int tupleWriteBinary(Uint8List buffer, ByteData data, Uint8List value, int offset) {
  final length = value.length;
  if (length <= 0xFF) {
    data.setUint8(offset++, 0xc4);
    data.setUint8(offset++, length);
    buffer.setRange(offset, offset + length, value);
    return offset + length;
  }
  if (length <= 0xFFFF) {
    buffer[offset++] = 0xc5;
    data.setUint16(offset, length);
    offset += 2;
    buffer.setRange(offset, offset + length, value);
    return offset + length;
  }
  if (length <= 0xFFFFFFFF) {
    data.setUint8(offset++, 0xc6);
    data.setUint32(offset, length);
    offset += 4;
    buffer.setRange(offset, offset + length, value);
    return offset + length;
  }
  throw ArgumentError('Max binary length is 0xFFFFFFFF');
}

@pragma(preferInlinePragma)
int tupleWriteList(ByteData data, int length, int offset) {
  if (length <= 0xF) {
    data.setUint8(offset++, 0x90 | length);
    return offset;
  }
  if (length <= 0xFFFF) {
    data.setUint8(offset++, 0xdc);
    data.setUint16(offset, length);
    return offset + 2;
  }
  if (length <= 0xFFFFFFFF) {
    data.setUint8(offset++, 0xdd);
    data.setUint32(offset, length);
    return offset + 4;
  }
  throw ArgumentError('Max list length is 4294967295');
}

@pragma(preferInlinePragma)
int tupleWriteMap(ByteData data, int length, int offset) {
  if (length <= 0xF) {
    data.setUint8(offset++, 0x80 | length);
    return offset;
  }
  if (length <= 0xFFFF) {
    data.setUint8(offset++, 0xde);
    data.setUint16(offset, length);
    return offset + 2;
  }
  if (length <= 0xFFFFFFFF) {
    data.setUint8(offset++, 0xdf);
    data.setUint32(offset, length);
    return offset + 4;
  }
  throw ArgumentError('Max map length is 4294967295');
}

@pragma(preferInlinePragma)
({bool? value, int offset}) tupleReadBool(ByteData data, int offset) {
  final value = data.getUint8(offset);
  switch (value) {
    case 0xc2:
      return (value: false, offset: offset + 1);
    case 0xc3:
      return (value: true, offset: offset + 1);
    case 0xc0:
      return (value: null, offset: offset + 1);
  }
  throw FormatException("Byte $value is not bool");
}

@pragma(preferInlinePragma)
({int? value, int offset}) tupleReadInt(ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  int? value;
  if (bytes <= 0x7f || bytes >= 0xe0) {
    value = data.getInt8(offset);
    return (value: value, offset: offset + 1);
  }
  switch (bytes) {
    case 0xcc:
      value = data.getUint8(++offset);
      return (value: value, offset: offset + 1);
    case 0xcd:
      value = data.getUint16(++offset);
      return (value: value, offset: offset + 2);
    case 0xce:
      value = data.getUint32(++offset);
      return (value: value, offset: offset + 4);
    case 0xcf:
      value = data.getUint64(++offset);
      return (value: value, offset: offset + 8);
    case 0xd0:
      value = data.getInt8(++offset);
      return (value: value, offset: offset + 1);
    case 0xd1:
      value = data.getInt16(++offset);
      return (value: value, offset: offset + 2);
    case 0xd2:
      value = data.getInt32(++offset);
      return (value: value, offset: offset + 4);
    case 0xd3:
      value = data.getInt64(++offset);
      return (value: value, offset: offset + 8);
    case 0xc0:
      value = null;
      return (value: value, offset: offset + 1);
  }
  throw FormatException("Byte $value is not int");
}

@pragma(preferInlinePragma)
({double? value, int offset}) tupleReadDouble(ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  double? value;
  switch (bytes) {
    case 0xca:
      value = data.getFloat32(++offset);
      return (value: value, offset: offset + 4);
    case 0xcb:
      value = data.getFloat64(++offset);
      return (value: value, offset: offset + 8);
    case 0xc0:
      value = null;
      return (value: value, offset: offset + 1);
  }
  throw FormatException("Byte $value is not double");
}

@pragma(preferInlinePragma)
({String? value, int offset}) tupleReadString(Uint8List buffer, ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  final innerBuffer = buffer.buffer;
  final offsetInBytes = buffer.offsetInBytes;
  if (bytes == 0xc0) {
    return (value: null, offset: offset + 1);
  }
  int length;
  if (bytes & 0xE0 == 0xA0) {
    length = bytes & 0x1F;
    offset += 1;
    final view = innerBuffer.asUint8List(offsetInBytes + offset, length);
    return (value: _decoder.convert(view), offset: offset + length);
  }
  switch (bytes) {
    case 0xc0:
      return (value: null, offset: offset + 1);
    case 0xd9:
      length = data.getUint8(++offset);
      offset += 1;
      return (value: _decoder.convert(innerBuffer.asUint8List(offsetInBytes + offset, length)), offset: offset + length);
    case 0xda:
      length = data.getUint16(++offset);
      offset += 2;
      return (value: _decoder.convert(innerBuffer.asUint8List(offsetInBytes + offset, length)), offset: offset + length);
    case 0xdb:
      length = data.getUint32(++offset);
      offset += 4;
      return (value: _decoder.convert(innerBuffer.asUint8List(offsetInBytes + offset, length)), offset: offset + length);
  }
  throw FormatException("Byte $bytes is not string");
}

@pragma(preferInlinePragma)
({Uint8List value, int offset}) tupleReadBinary(Uint8List buffer, ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  final innerBuffer = buffer.buffer;
  final offsetInBytes = buffer.offsetInBytes;
  int length;
  switch (bytes) {
    case 0xc4:
      length = data.getUint8(++offset);
      offset += 1;
      return (value: innerBuffer.asUint8List(offsetInBytes + offset, length), offset: offset + length);
    case 0xc0:
      length = 0;
      offset += 1;
      return (value: innerBuffer.asUint8List(offsetInBytes + offset, length), offset: offset + length);
    case 0xc5:
      length = data.getUint16(++offset);
      offset += 2;
      return (value: innerBuffer.asUint8List(offsetInBytes + offset, length), offset: offset + length);
    case 0xc6:
      length = data.getUint32(++offset);
      offset += 4;
      return (value: innerBuffer.asUint8List(offsetInBytes + offset, length), offset: offset + length);
  }
  throw FormatException("Byte $bytes is not binary");
}

@pragma(preferInlinePragma)
({int length, int offset}) tupleReadList(ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  if (bytes & 0xF0 == 0x90) {
    return (length: bytes & 0xF, offset: offset + 1);
  }
  switch (bytes) {
    case 0xc0:
      return (length: offset += 1, offset: 0);
    case 0xdc:
      return (length: data.getUint16(++offset), offset: offset + 2);
    case 0xdd:
      return (length: data.getUint32(++offset), offset: offset + 4);
  }
  throw FormatException("Byte $bytes is invalid list length");
}

@pragma(preferInlinePragma)
({int length, int offset}) tupleReadMap(ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  if (bytes & 0xF0 == 0x80) {
    return (length: bytes & 0xF, offset: offset + 1);
  }
  switch (bytes) {
    case 0xc0:
      return (length: offset += 1, offset: 0);
    case 0xde:
      return (length: data.getUint16(++offset), offset: offset + 2);
    case 0xdf:
      return (length: data.getUint32(++offset), offset: offset + 4);
  }
  throw FormatException("Byte $bytes is invalid map length");
}

@pragma(preferInlinePragma)
int tupleSizeOfInt(int number) {
  if (number >= -0x20) {
    return 1;
  }
  if (number >= -127 && number <= 127) {
    return 2;
  }
  if (number >= -327678 && number <= 0xFFFF) {
    return 3;
  }
  if (number >= -2147483648 && number <= 0xFFFFFFFF) {
    return 5;
  }
  return 9;
}

@pragma(preferInlinePragma)
int tupleSizeOfString(int length) {
  if (length <= 0x1F) {
    return 1 + length;
  }
  if (length <= 0xFFFF) {
    return 2 + length;
  }
  if (length <= 0xFFFFFFFF) {
    return 3 + length;
  }
  return 5 + length;
}

@pragma(preferInlinePragma)
int tupleSizeOfBinary(int length) {
  if (length <= 0xFF) {
    return 2;
  }
  if (length <= 0xFFFF) {
    return 3;
  }
  return 5;
}

@pragma(preferInlinePragma)
int tupleSizeOfList(int length) {
  if (length <= 0xF) {
    return 1;
  }
  if (length <= 0xFFFF) {
    return 3;
  }
  return 5;
}

@pragma(preferInlinePragma)
int tupleSizeOfMap(int length) {
  if (length <= 0xF) {
    return 1;
  }
  if (length <= 0xFFFF) {
    return 3;
  }
  return 5;
}

class InteractorTuples {
  final Pointer<interactor_dart> _interactor;

  late final (Pointer<Uint8>, int) emptyList;
  late final (Pointer<Uint8>, int) emptyMap;

  InteractorTuples(this._interactor) {
    emptyList = _createEmptyList();
    emptyMap = _createEmptyMap();
  }

  @pragma(preferInlinePragma)
  int next(Pointer<Uint8> pointer, int offset) => interactor_dart_tuple_next(pointer.cast(), offset);

  @pragma(preferInlinePragma)
  Pointer<Uint8> allocate(int capacity) => interactor_dart_data_allocate(_interactor, capacity).cast();

  @pragma(preferInlinePragma)
  (Pointer<Uint8>, Uint8List, ByteData) prepare(int size) {
    final pointer = interactor_dart_data_allocate(_interactor, size).cast<Uint8>();
    final buffer = pointer.asTypedList(size);
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes);
    return (pointer, buffer, data);
  }

  @pragma(preferInlinePragma)
  void free(Pointer<Uint8> tuple, int size) => interactor_dart_data_free(_interactor, tuple.cast(), size);

  (Pointer<Uint8>, int) _createEmptyList() {
    final size = tupleSizeOfList(0);
    final list = allocate(size);
    final buffer = list.asTypedList(size);
    tupleWriteList(ByteData.view(buffer.buffer, buffer.offsetInBytes), 0, 0);
    return (list, size);
  }

  (Pointer<Uint8>, int) _createEmptyMap() {
    final size = tupleSizeOfMap(0);
    final map = allocate(size);
    final buffer = map.asTypedList(size);
    tupleWriteMap(ByteData.view(buffer.buffer, buffer.offsetInBytes), 0, 0);
    return (map, size);
  }
}

abstract interface class InteractorTuple {
  int get tupleSize;

  int serialize(Uint8List buffer, ByteData data, int offset);
}

extension InteractorTupleIntExtension on int {
  @pragma(preferInlinePragma)
  int get tupleSize => tupleSizeOfInt(this);

  @pragma(preferInlinePragma)
  int writeToTuple(ByteData data, int offset) => tupleWriteInt(data, this, offset);
}

extension InteractorTupleDoubleExtension on double {
  @pragma(preferInlinePragma)
  int get tupleSize => tupleSizeOfDouble;

  @pragma(preferInlinePragma)
  int writeToTuple(ByteData data, int offset) => tupleWriteDouble(data, this, offset);
}

extension InteractorTupleBooleanExtension on bool {
  @pragma(preferInlinePragma)
  int get tupleSize => tupleSizeOfBool;

  @pragma(preferInlinePragma)
  int writeToTuple(ByteData data, int offset) => tupleWriteBool(data, this, offset);
}

extension InteractorTupleStringExtension on String {
  @pragma(preferInlinePragma)
  int get tupleSize => tupleSizeOfString(length);

  @pragma(preferInlinePragma)
  int writeToTuple(Uint8List buffer, ByteData data, int offset) => tupleWriteString(buffer, data, this, offset);
}

extension InteractorTupleBinaryExtension on Uint8List {
  @pragma(preferInlinePragma)
  int get tupleSize => tupleSizeOfBinary(length);

  @pragma(preferInlinePragma)
  int writeToTuple(Uint8List buffer, ByteData data, int offset) => tupleWriteBinary(buffer, data, this, offset);
}

extension InteractorTupleMapExtension<K, V> on Map<K, V> {
  @pragma(preferInlinePragma)
  int get tupleSize => tupleSizeOfMap(length);

  @pragma(preferInlinePragma)
  int computeTupleSize() {
    var size = tupleSize;
    for (var entry in entries) {
      switch (entry.key) {
        case null:
          size += tupleSizeOfNull;
          break;
        case int asInt:
          size += asInt.tupleSize;
          break;
        case double:
          size += tupleSizeOfDouble;
          break;
        case bool:
          size += tupleSizeOfBool;
          break;
        case String asString:
          size += asString.tupleSize;
          break;
        case Uint8List asBinary:
          size += asBinary.tupleSize;
          break;
        case List asList:
          size += asList.computeTupleSize();
          break;
        case Map asMap:
          size += asMap.computeTupleSize();
          break;
        case InteractorTuple asTuple:
          size += asTuple.tupleSize;
          break;
      }
      switch (entry.value) {
        case null:
          size += tupleSizeOfNull;
          break;
        case int asInt:
          size += asInt.tupleSize;
          break;
        case double:
          size += tupleSizeOfDouble;
          break;
        case bool:
          size += tupleSizeOfBool;
          break;
        case String asString:
          size += asString.tupleSize;
          break;
        case Uint8List asBinary:
          size += asBinary.tupleSize;
          break;
        case List asList:
          size += asList.computeTupleSize();
          break;
        case Map asMap:
          size += asMap.computeTupleSize();
          break;
        case InteractorTuple asTuple:
          size += asTuple.tupleSize;
          break;
      }
    }
    return size;
  }

  @pragma(preferInlinePragma)
  int writeToTuple(Uint8List buffer, ByteData data, int offset) => tupleWriteMap(data, length, offset);

  @pragma(preferInlinePragma)
  int serializeToTuple(Uint8List buffer, ByteData data, int offset) {
    offset = tupleWriteMap(data, length, offset);
    for (var entry in entries) {
      switch (entry.key) {
        case null:
          offset = tupleWriteNull(data, offset);
          break;
        case int asInt:
          offset = tupleWriteInt(data, asInt, offset);
          break;
        case double asDouble:
          offset = tupleWriteDouble(data, asDouble, offset);
          break;
        case bool asBool:
          offset = tupleWriteBool(data, asBool, offset);
          break;
        case String asString:
          offset = tupleWriteString(buffer, data, asString, offset);
          break;
        case Uint8List asBinary:
          offset = tupleWriteBinary(buffer, data, asBinary, offset);
          break;
        case List asList:
          offset = asList.serializeToTuple(buffer, data, offset);
          break;
        case Map asMap:
          offset = asMap.serializeToTuple(buffer, data, offset);
          break;
        case InteractorTuple asTuple:
          offset = asTuple.serialize(buffer, data, offset);
          break;
      }
      switch (entry.value) {
        case null:
          offset = tupleWriteNull(data, offset);
          break;
        case int asInt:
          offset = tupleWriteInt(data, asInt, offset);
          break;
        case double asDouble:
          offset = tupleWriteDouble(data, asDouble, offset);
          break;
        case bool asBool:
          offset = tupleWriteBool(data, asBool, offset);
          break;
        case String asString:
          offset = tupleWriteString(buffer, data, asString, offset);
          break;
        case Uint8List asBinary:
          offset = tupleWriteBinary(buffer, data, asBinary, offset);
          break;
        case List asList:
          offset = asList.serializeToTuple(buffer, data, offset);
          break;
        case Map asMap:
          offset = asMap.serializeToTuple(buffer, data, offset);
          break;
        case InteractorTuple asTuple:
          offset = asTuple.serialize(buffer, data, offset);
          break;
      }
    }
    return offset;
  }
}

extension InteractorTupleListExtension<T> on List<T> {
  @pragma(preferInlinePragma)
  int get tupleSize => tupleSizeOfList(length);

  @pragma(preferInlinePragma)
  int writeToTuple(Uint8List buffer, ByteData data, int offset) => tupleWriteList(data, length, offset);

  @pragma(preferInlinePragma)
  int computeTupleSize() {
    var size = tupleSize;
    for (var entry in this) {
      switch (entry) {
        case null:
          size += tupleSizeOfNull;
          break;
        case int asInt:
          size += asInt.tupleSize;
          break;
        case double:
          size += tupleSizeOfDouble;
          break;
        case bool:
          size += tupleSizeOfBool;
          break;
        case String asString:
          size += asString.tupleSize;
          break;
        case Uint8List asBinary:
          size += asBinary.tupleSize;
          break;
        case List asList:
          size += asList.computeTupleSize();
          break;
        case Map asMap:
          size += asMap.computeTupleSize();
          break;
        case InteractorTuple asTuple:
          size += asTuple.tupleSize;
          break;
      }
    }
    return size;
  }

  @pragma(preferInlinePragma)
  int serializeToTuple(Uint8List buffer, ByteData data, int offset) {
    offset = tupleWriteList(data, length, offset);
    for (var entry in this) {
      switch (entry) {
        case null:
          offset = tupleWriteNull(data, offset);
          break;
        case int asInt:
          offset = tupleWriteInt(data, asInt, offset);
          break;
        case double asDouble:
          offset = tupleWriteDouble(data, asDouble, offset);
          break;
        case bool asBool:
          offset = tupleWriteBool(data, asBool, offset);
          break;
        case String asString:
          offset = tupleWriteString(buffer, data, asString, offset);
          break;
        case Uint8List asBinary:
          offset = tupleWriteBinary(buffer, data, asBinary, offset);
          break;
        case List asList:
          offset = asList.serializeToTuple(buffer, data, offset);
          break;
        case Map asMap:
          offset = asMap.serializeToTuple(buffer, data, offset);
          break;
        case InteractorTuple asTuple:
          offset = asTuple.serialize(buffer, data, offset);
          break;
      }
    }
    return offset;
  }
}
