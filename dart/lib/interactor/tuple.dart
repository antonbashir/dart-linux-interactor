import 'dart:convert';
import 'dart:typed_data';
import 'dart:ffi';
import 'bindings.dart';
import 'constants.dart';

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
    if (value <= 127) {
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
      offset += 2;
      return offset;
    }
    if (value <= 0xFFFFFFFF) {
      data.setUint8(offset++, 0xce);
      data.setUint32(offset, value);
      offset += 4;
      return offset;
    }
    data.setUint8(offset++, 0xcf);
    data.setUint64(offset, value);
    offset += 8;
    return offset;
  }
  if (value >= -32) {
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
    offset += 2;
    return offset;
  }
  if (value >= -2147483648) {
    data.setUint8(offset++, 0xd2);
    data.setInt32(offset, value);
    offset += 4;
    return offset;
  }
  data.setUint8(offset++, 0xd3);
  data.setInt64(offset, value);
  offset += 8;
  return offset;
}

@pragma(preferInlinePragma)
int tupleWriteDouble(ByteData data, double value, int offset) {
  data.setUint8(offset++, 0xcb);
  data.setFloat64(offset, value);
  offset += 8;
  return offset;
}

@pragma(preferInlinePragma)
int tupleWriteString(Uint8List buffer, ByteData data, String value, int offset) {
  final encoded = utf8.encode(value);
  final length = encoded.length;
  if (length <= 31) {
    data.setUint8(offset++, 0xA0 | length);
    buffer.setRange(offset, offset + encoded.length, encoded);
    offset += encoded.length;
    return offset;
  }
  if (length <= 0xFF) {
    data.setUint8(offset++, 0xd9);
    data.setUint8(offset++, length);
    buffer.setRange(offset, offset + encoded.length, encoded);
    offset += encoded.length;
    return offset;
  }
  if (length <= 0xFFFF) {
    data.setUint8(offset++, 0xda);
    data.setUint16(offset, length);
    offset += 2;
    buffer.setRange(offset, offset + encoded.length, encoded);
    offset += encoded.length;
    return offset;
  }
  if (length <= 0xFFFFFFFF) {
    data.setUint8(offset++, 0xdb);
    data.setUint32(offset, length);
    offset += 4;
    buffer.setRange(offset, offset + encoded.length, encoded);
    offset += encoded.length;
    return offset;
  }
  throw ArgumentError('Max String length is 0xFFFFFFFF');
}

@pragma(preferInlinePragma)
int tupleWriteBinary(Uint8List buffer, ByteData data, Uint8List value, int offset) {
  final length = value.length;
  if (length <= 0xFF) {
    data.setUint8(offset++, 0xc4);
    data.setUint8(offset++, length);
    buffer.setRange(offset, offset + length, value);
    offset += length;
    return offset;
  }
  if (length <= 0xFFFF) {
    buffer[offset++] = 0xc5;
    data.setUint16(offset, length);
    offset += 2;
    buffer.setRange(offset, offset + length, value);
    offset += length;
    return offset;
  }
  if (length <= 0xFFFFFFFF) {
    data.setUint8(offset++, 0xc6);
    data.setUint32(offset, length);
    offset += 4;
    buffer.setRange(offset, offset + length, value);
    offset += length;
    return offset;
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
    offset += 2;
    return offset;
  }
  if (length <= 0xFFFFFFFF) {
    data.setUint8(offset++, 0xdd);
    data.setUint32(offset, length);
    offset += 4;
    return offset;
  }
  throw ArgumentError('Max length is 4294967295');
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
    offset += 2;
    return offset;
  }
  if (length <= 0xFFFFFFFF) {
    data.setUint8(offset++, 0xdf);
    data.setUint32(offset, length);
    offset += 4;
    return offset;
  }
  throw ArgumentError('Max length is 4294967295');
}

@pragma(preferInlinePragma)
({bool? value, int offset}) tupleReadBool(ByteData data, int offset) {
  final value = data.getUint8(offset);
  if (value == 0xc2) return (value: false, offset: offset + 1);
  if (value == 0xc3) return (value: true, offset: offset + 1);
  if (value == 0xc0) return (value: null, offset: offset + 1);
  throw FormatException('bool', value);
}

({int? value, int offset}) tupleReadInt(ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  int? value;
  if (bytes <= 0x7f || bytes >= 0xe0) {
    value = data.getInt8(offset);
    offset += 1;
    return (value: value, offset: offset);
  }
  switch (bytes) {
    case 0xcc:
      value = data.getUint8(++offset);
      offset += 1;
      return (value: value, offset: offset);
    case 0xcd:
      value = data.getUint16(++offset);
      offset += 2;
      return (value: value, offset: offset);
    case 0xce:
      value = data.getUint32(++offset);
      offset += 4;
      return (value: value, offset: offset);
    case 0xcf:
      value = data.getUint64(++offset);
      offset += 8;
      return (value: value, offset: offset);
    case 0xd0:
      value = data.getInt8(++offset);
      offset += 1;
      return (value: value, offset: offset);
    case 0xd1:
      value = data.getInt16(++offset);
      offset += 2;
      return (value: value, offset: offset);
    case 0xd2:
      value = data.getInt32(++offset);
      offset += 4;
      return (value: value, offset: offset);
    case 0xd3:
      value = data.getInt64(++offset);
      offset += 8;
      return (value: value, offset: offset);
    case 0xc0:
      value = null;
      offset += 1;
      return (value: value, offset: offset);
  }
  throw FormatException('bool', value);
}

@pragma(preferInlinePragma)
({double? value, int offset}) tupleReadDouble(ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  double? value;
  switch (bytes) {
    case 0xca:
      value = data.getFloat32(++offset);
      offset += 4;
      return (value: value, offset: offset);
    case 0xcb:
      value = data.getFloat64(++offset);
      offset += 8;
      return (value: value, offset: offset);
    case 0xc0:
      value = null;
      offset += 1;
      return (value: value, offset: offset);
  }
  throw FormatException('double', bytes);
}

@pragma(preferInlinePragma)
({String? value, int offset}) tupleReadString(Uint8List buffer, ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  if (bytes == 0xc0) {
    return (value: null, offset: offset + 1);
  }
  int length;
  if (bytes & 0xE0 == 0xA0) {
    length = bytes & 0x1F;
    offset += 1;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (value: utf8.decode(view), offset: offset);
  }
  switch (bytes) {
    case 0xc0:
      return (value: null, offset: offset + 1);
    case 0xd9:
      length = data.getUint8(++offset);
      offset += 1;
      final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
      offset += length;
      return (value: utf8.decode(view), offset: offset);
    case 0xda:
      length = data.getUint16(++offset);
      offset += 2;
      final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
      offset += length;
      return (value: utf8.decode(view), offset: offset);
    case 0xdb:
      length = data.getUint32(++offset);
      offset += 4;
      final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
      offset += length;
      return (value: utf8.decode(view), offset: offset);
  }
  throw FormatException('double', bytes);
}

@pragma(preferInlinePragma)
({Uint8List value, int offset}) tupleReadBinary(Uint8List buffer, ByteData data, int offset) {
  final bytes = data.getUint8(offset);
  int length;
  switch (bytes) {
    case 0xc4:
      length = data.getUint8(++offset);
      offset += 1;
      final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
      offset += length;
      return (value: view, offset: offset);
    case 0xc0:
      length = 0;
      offset += 1;
      final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
      offset += length;
      return (value: view, offset: offset);
    case 0xc5:
      length = data.getUint16(++offset);
      offset += 2;
      final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
      offset += length;
      return (value: view, offset: offset);
    case 0xc6:
      length = data.getUint32(++offset);
      offset += 4;
      final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
      offset += length;
      return (value: view, offset: offset);
  }
  throw FormatException('double');
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
  throw FormatException('double');
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
  throw FormatException('double');
}

const tupleSizeOfNull = 1;
const tupleSizeOfBool = 1;
const tupleSizeOfDouble = 1 + 8;

@pragma(preferInlinePragma)
int tupleSizeOfInt(int number) {
  if (number >= -0x20) {
    return 1;
  }
  if (number >= -127 && number <= 127) {
    return 1 + 1;
  }
  if (number >= (-32767 - 1) && number <= 0xFFFF) {
    return 1 + 2;
  }
  if (number >= (-2147483647 - 1) && number <= 0xFFFFFFFF) {
    return 1 + 4;
  }
  return 1 + 8;
}

@pragma(preferInlinePragma)
int tupleSizeOfString(int length) {
  if (length <= 31) {
    return 1 + length;
  }
  if (length <= 0xFFFF) {
    return 1 + 1 + length;
  }
  if (length <= 0xFFFFFFFF) {
    return 1 + 2 + length;
  }
  return 1 + 4 + length;
}

@pragma(preferInlinePragma)
int tupleSizeOfBinary(int length) {
  if (length <= 255) {
    return 1 + 1;
  }
  if (length <= 0xFFFF) {
    return 1 + 2;
  }
  return 1 + 4;
}

@pragma(preferInlinePragma)
int tupleSizeOfList(int length) {
  if (length <= 15) {
    return 1;
  }
  if (length <= 0xFFFF) {
    return 1 + 2;
  }
  return 1 + 4;
}

@pragma(preferInlinePragma)
int tupleSizeOfMap(int length) {
  if (length <= 15) {
    return 1;
  }
  if (length <= 0xFFFF) {
    return 1 + 2;
  }
  return 1 + 4;
}

class InteractorTuples {
  final InteractorBindings _bindings;
  final Pointer<interactor_dart_t> _interactor;

  InteractorTuples(this._bindings, this._interactor);

  @pragma(preferInlinePragma)
  Pointer<Uint8> allocate(int size) => Pointer<Uint8>.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, size));

  @pragma(preferInlinePragma)
  void free(Pointer<Uint8> tuple, int size) => _bindings.interactor_dart_data_free(_interactor, tuple.address, size);

  @pragma(preferInlinePragma)
  int next(Pointer<Uint8> pointer, int offset) => _bindings.interactor_dart_tuple_next(offset, pointer.cast());
}
