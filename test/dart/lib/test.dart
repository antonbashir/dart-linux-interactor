import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:linux_interactor/linux_interactor.dart';
import 'package:linux_interactor_test/call.dart';
import 'package:linux_interactor_test/threading.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  using((Arena arena) => dlopen("${dirname(Platform.script.toFilePath())}/../native/libinteractortest.so".toNativeUtf8(allocator: arena).cast(), rtldGlobal | rtldLazy));

  group("[call native]", testCallNative);
  group("[call dart]", testCallDart);
  group("[threading native]", () {
    for (var i = 0; i < 100; i++) {
      testThreadingNative();
    }
  });
  group("[threading dart]", () {
    for (var i = 0; i < 100; i++) {
      testThreadingDart();
    }
  });
}
