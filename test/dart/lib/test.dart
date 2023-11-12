import 'dart:ffi';
import 'dart:io';

import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/call.dart';
import 'package:linux_interactor_test/threading.dart';
import 'package:linux_interactor_test/timeout.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

TestBindings loadBindings() => TestBindings(DynamicLibrary.open("${dirname(Platform.script.toFilePath())}/../native/libinteractortest.so"));

void main() {
  group("[call native]", testCallNative);
  group("[call dart]", testCallDart);
  group("[timeout native]", testTimeoutNative);
  group("[timeout dart]", testTimeoutDart);
  group("[threading native]", testThreadingNative);
  group("[threading dart]", testThreadingDart);
}
