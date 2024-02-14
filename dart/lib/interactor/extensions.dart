import 'dart:typed_data';

import 'constants.dart';

const int _oneByteLimit = 0x7f;
const int _twoByteLimit = 0x7ff;
const int _surrogateTagMask = 0xFC00;
const int _surrogateValueMask = 0x3FF;
const int _leadSurrogateMin = 0xD800;

@pragma(preferInlinePragma)
int fastEncodeString(String string, Uint8List buffer, int offset) {
  final startOffset = offset;
  for (var stringIndex = 0; stringIndex < string.length; stringIndex++) {
    final codeUnit = string.codeUnitAt(stringIndex);
    if (codeUnit <= _oneByteLimit) {
      buffer[offset++] = codeUnit;
    } else if ((codeUnit & _surrogateTagMask) == _leadSurrogateMin) {
      final nextCodeUnit = string.codeUnitAt(++stringIndex);
      final rune = 0x10000 + ((codeUnit & _surrogateValueMask) << 10) | (nextCodeUnit & _surrogateValueMask);
      buffer[offset++] = 0xF0 | (rune >> 18);
      buffer[offset++] = 0x80 | ((rune >> 12) & 0x3f);
      buffer[offset++] = 0x80 | ((rune >> 6) & 0x3f);
      buffer[offset++] = 0x80 | (rune & 0x3f);
    } else if (codeUnit <= _twoByteLimit) {
      buffer[offset++] = 0xC0 | (codeUnit >> 6);
      buffer[offset++] = 0x80 | (codeUnit & 0x3f);
    } else {
      buffer[offset++] = 0xE0 | (codeUnit >> 12);
      buffer[offset++] = 0x80 | ((codeUnit >> 6) & 0x3f);
      buffer[offset++] = 0x80 | (codeUnit & 0x3f);
    }
  }
  return offset - startOffset;
}
