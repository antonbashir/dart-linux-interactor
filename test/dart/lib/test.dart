import 'dart:ffi';
import 'dart:io';

import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/call.dart';
import 'package:linux_interactor_test/threading.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

TestBindings loadBindings() {
  Interactor();
  return TestBindings(DynamicLibrary.open("${dirname(Platform.script.toFilePath())}/../native/libinteractortest.so"));
}

void main() {
  loadBindings().test_initialize();
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
