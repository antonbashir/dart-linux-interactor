import 'dart:convert';
import 'dart:typed_data';
import 'dart:ffi';
import 'bindings.dart';
import 'constants.dart';

@pragma(preferInlinePragma)
int tuplePutNull(ByteData data, {int offset = 0}) {
  data.setUint8(offset++, 0xc0);
  return offset;
}

@pragma(preferInlinePragma)
int tuplePutBool(ByteData data, bool? value, {int offset = 0}) {
  if (value == null) {
    data.setUint8(offset++, 0xc0);
    return offset;
  }
  data.setUint8(offset++, value ? 0xc3 : 0xc2);
  return offset;
}

@pragma(preferInlinePragma)
int tuplePutInt(ByteData data, int? value, {int offset = 0}) {
  if (value == null) {
    data.setUint8(offset++, 0xc0);
    return offset;
  }
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
int tuplePutDouble(ByteData data, double value, {int offset = 0}) {
  data.setUint8(offset++, 0xcb);
  data.setFloat64(offset, value);
  offset += 8;
  return offset;
}

@pragma(preferInlinePragma)
int tuplePutString(Uint8List buffer, ByteData data, String value, {int offset = 0}) {
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
int tuplePutBinary(Uint8List buffer, ByteData data, Uint8List value, {int offset = 0}) {
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
int tuplePutList(ByteData data, int length, {int offset = 0}) {
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
int tuplePutMap(ByteData data, int length, {int offset = 0}) {
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
(bool?, int) tupleTakeBool(ByteData data, {int offset = 0}) {
  final value = data.getUint8(offset);
  if (value == 0xc2) {
    return (false, offset + 1);
  }
  if (value == 0xc3) {
    return (true, offset + 1);
  }
  if (value == 0xc0) {
    return (null, offset + 1);
  }
  throw FormatException('bool', value);
}

(int?, int) tupleTakeInt(ByteData data, {int offset = 0}) {
  final bytes = data.getUint8(offset);
  int? value;
  if (bytes <= 0x7f || bytes >= 0xe0) {
    value = data.getInt8(offset);
    offset += 1;
    return (value, offset);
  }
  if (bytes == 0xcc) {
    value = data.getUint8(++offset);
    offset += 1;
    return (value, offset);
  }
  if (bytes == 0xcd) {
    value = data.getUint16(++offset);
    offset += 2;
    return (value, offset);
  }
  if (bytes == 0xce) {
    value = data.getUint32(++offset);
    offset += 4;
    return (value, offset);
  }
  if (bytes == 0xcf) {
    value = data.getUint64(++offset);
    offset += 8;
    return (value, offset);
  }
  if (bytes == 0xd0) {
    value = data.getInt8(++offset);
    offset += 1;
    return (value, offset);
  }
  if (bytes == 0xd1) {
    value = data.getInt16(++offset);
    offset += 2;
    return (value, offset);
  }
  if (bytes == 0xd2) {
    value = data.getInt32(++offset);
    offset += 4;
    return (value, offset);
  }
  if (bytes == 0xd3) {
    value = data.getInt64(++offset);
    offset += 8;
    return (value, offset);
  }
  if (bytes == 0xc0) {
    value = null;
    offset += 1;
    return (value, offset);
  }
  throw FormatException('bool', value);
}

@pragma(preferInlinePragma)
(double?, int) tupleTakeDouble(ByteData data, {int offset = 0}) {
  final bytes = data.getUint8(offset);
  double? value;
  if (bytes == 0xca) {
    value = data.getFloat32(++offset);
    offset += 4;
    return (value, offset);
  }
  if (bytes == 0xcb) {
    value = data.getFloat64(++offset);
    offset += 8;
    return (value, offset);
  }
  if (bytes == 0xc0) {
    value = null;
    offset += 1;
    return (value, offset);
  }
  throw FormatException('double', bytes);
}

@pragma(preferInlinePragma)
(String?, int) tupleTakeString(Uint8List buffer, ByteData data, {int offset = 0}) {
  final bytes = data.getUint8(offset);
  if (bytes == 0xc0) {
    return (null, offset + 1);
  }
  int length;
  if (bytes & 0xE0 == 0xA0) {
    length = bytes & 0x1F;
    offset += 1;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (utf8.decode(view), offset);
  }
  if (bytes == 0xc0) {
    return (null, offset + 1);
  }
  if (bytes == 0xd9) {
    length = data.getUint8(++offset);
    offset += 1;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (utf8.decode(view), offset);
  }
  if (bytes == 0xda) {
    length = data.getUint16(++offset);
    offset += 2;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (utf8.decode(view), offset);
  }
  if (bytes == 0xdb) {
    length = data.getUint32(++offset);
    offset += 4;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (utf8.decode(view), offset);
  }

  throw FormatException('double', bytes);
}

@pragma(preferInlinePragma)
(Uint8List, int) tupleTakeBinary(Uint8List buffer, ByteData data, {int offset = 0}) {
  final b = data.getUint8(offset);
  int length;
  if (b == 0xc4) {
    length = data.getUint8(++offset);
    offset += 1;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (view, offset);
  }
  if (b == 0xc0) {
    length = 0;
    offset += 1;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (view, offset);
  }
  if (b == 0xc5) {
    length = data.getUint16(++offset);
    offset += 2;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (view, offset);
  }
  if (b == 0xc6) {
    length = data.getUint32(++offset);
    offset += 4;
    final view = buffer.buffer.asUint8List(buffer.offsetInBytes + offset, length);
    offset += length;
    return (view, offset);
  }
  throw FormatException(
    'double',
  );
}

@pragma(preferInlinePragma)
(int, int) tupleTakeList(ByteData data, {int offset = 0}) {
  final bytes = data.getUint8(offset);
  if (bytes & 0xF0 == 0x90) {
    return (bytes & 0xF, offset + 1);
  }
  if (bytes == 0xc0) {
    return (offset += 1, 0);
  }
  if (bytes == 0xdc) {
    return (data.getUint16(++offset), offset + 2);
  }
  if (bytes == 0xdd) {
    return (data.getUint32(++offset), offset += 4);
  }
  throw FormatException(
    'double',
  );
}

@pragma(preferInlinePragma)
(int, int) tupleTakeMap(ByteData data, {int offset = 0}) {
  final bytes = data.getUint8(offset);
  if (bytes & 0xF0 == 0x80) {
    return (bytes & 0xF, offset + 1);
  }
  if (bytes == 0xc0) {
    return (offset += 1, 0);
  }
  if (bytes == 0xde) {
    return (data.getUint16(++offset), offset + 2);
  }
  if (bytes == 0xdf) {
    return (data.getUint32(++offset), offset += 4);
  }
  throw FormatException(
    'double',
  );
}

@pragma(preferInlinePragma)
int tupleSizeOfString(String value) {
  final length = value.length;
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

class InteractorTuples {
  final InteractorBindings _bindings;
  final Pointer<interactor_dart_t> _interactor;

  InteractorTuples(this._bindings, this._interactor);

  @pragma(preferInlinePragma)
  Pointer<Uint8> allocate(int size) => Pointer<Uint8>.fromAddress(_bindings.interactor_dart_data_allocate(_interactor, size));

  @pragma(preferInlinePragma)
  void free(Pointer<Uint8> tuple, int size) => _bindings.interactor_dart_data_free(_interactor, tuple.address, size);
}
