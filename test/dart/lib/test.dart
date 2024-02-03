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
  //     testThreadingDart();offset
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
    final size = tupleSizeOfBool + tupleSizeOfString("test-1".length) + tupleSizeOfString("test-2".length);
    for (var i = 0; i < 1000000; i++) {
      final pointer = tuples.allocate(size);
      final buffer = pointer.asTypedList(size);
      final data = ByteData.view(buffer.buffer, buffer.offsetInBytes);
      var offset = 0;
      offset = tupleWriteBool(data, false, 0);
      offset = tupleWriteString(buffer, data, "test-1", offset);
      offset = tupleWriteString(buffer, data, "test-2", offset);
      offset = tuples.next(pointer, 0);
      var result = tupleReadString(buffer, data, offset);
      result = tupleReadString(buffer, data, result.offset);
      tuples.free(pointer, size);
    }
    print(sw.elapsedMicroseconds);
    print(sw.elapsedMilliseconds);

    await completer.future;
    await interactor.shutdown();
  });
}
