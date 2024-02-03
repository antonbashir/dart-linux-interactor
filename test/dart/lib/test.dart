import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:linux_interactor/interactor/tuple.dart';
import 'package:linux_interactor/linux_interactor.dart';
import 'package:linux_interactor_test/bindings.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

TestBindings loadBindings() => TestBindings(DynamicLibrary.open("${dirname(Platform.script.toFilePath())}/../native/libinteractortest.so"));

void main() {
  // group("[call native]", testCallNative);
  // group("[call dart]", testCallDart);
  // group("[threading native]", () {
  //   for (var i = 0; i < 100; i++) {
  //     testThreadingNative();
  //   }
  // });
  // group("[threading dart]", () {
  //   for (var i = 0; i < 100; i++) {
  //     testThreadingDart();
  //   }
  // });
  test("test", () async {
    final interactor = Interactor();
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    await worker.initialize();
    final completer = Completer();
    worker.activate();

    final tuples = worker.tuples;

    final sw = Stopwatch();
    sw.start();
    for (var i = 0; i < 1000000; i++) {
      final pointer = tuples.allocate(1024);
      final buffer = pointer.asTypedList(1024);
      final data = ByteData.view(buffer.buffer, buffer.offsetInBytes);
      var offset = tupleWriteBool(data, false);
      tupleWriteString(buffer, data, "test", offset: offset);
      var (result, resultOffset) = tupleReadString(buffer, data);
      print(result);
      print(tupleReadBool(data, offset: resultOffset));
    }
    print("micro: ${sw.elapsedMicroseconds}");
    print("ms: ${sw.elapsedMilliseconds}");
    print("s: ${sw.elapsed.inSeconds}");

    await completer.future;
    await interactor.shutdown();
  });
}
