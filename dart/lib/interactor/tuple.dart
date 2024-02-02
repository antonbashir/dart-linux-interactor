import 'dart:typed_data';

import 'constants.dart';

extension InteractorDataTupleExtensions on ByteData {
  @pragma(preferInlinePragma)
  int packNull({int offset = 0}) {
    setUint8(offset++, 0xc0);
    return offset;
  }
}
