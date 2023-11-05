import 'dart:ffi';

import 'package:linux_interactor_test/bindings.dart';
import 'package:linux_interactor_test/call.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'package:path/path.dart';

TestBindings loadBindings() => TestBindings(DynamicLibrary.open("${dirname(Platform.script.toFilePath())}/../native/libinteractortest.so"));

void main() {
  group("[call]", testCall);
}
