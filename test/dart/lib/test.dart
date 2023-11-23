import 'dart:ffi';
import 'dart:io';

import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/call.dart';
import 'package:linux_interactor_test/threading.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

TestBindings loadBindings() => TestBindings(DynamicLibrary.open("${dirname(Platform.script.toFilePath())}/../native/libinteractortest.so"));

void main() {
  group("[call native]", testCallNative);
  group("[call dart]", testCallDart);
  // group("[threading native]", () {
  //   for (var i = 0; i < 1000; i++) {
  //     testThreadingNative();
  //   }
  // });
  group("[threading dart]", () {
    for (var i = 0; i < 1000; i++) {
      testThreadingDart();
    }
  });
}
