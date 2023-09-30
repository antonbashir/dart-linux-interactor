import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart';

import 'package:ffi/ffi.dart';
import 'bindings.dart' as test;
import 'package:linux_interactor/interactor/bindings.dart';
import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor/interactor/defaults.dart';
import 'package:linux_interactor/interactor/interactor.dart';
import 'package:linux_interactor/interactor/worker.dart';

class TestNativeConsumer implements NativeConsumer {
  void test(Pointer<interactor_message_t> message) {
    print("Hello, C");
  }

  @override
  List<NativeCallback> callbacks() => [NativeCallback(test)];
}

class TestNativeProducer extends NativeProducer {
  final test.TestBindings _bindings;
  TestNativeProducer(this._bindings);

  late final testSendToNative = synchronous(_bindings.addresses.test_send_to_native);

  @override
  List<NativeMethod> methods() => [NativeMethod(_bindings.addresses.test_send_to_native)];
}

Future<void> main() async {
  final interactor = Interactor();
  final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
  final bindings = test.TestBindings(DynamicLibrary.open("${dirname(Platform.script.toFilePath())}/native/libinteractortest.so"));
  await worker.initialize();
  worker.consumer(TestNativeConsumer());
  final producer = worker.producer(TestNativeProducer(bindings));
  worker.activate();
  final native = using((Arena arena) {
    final interactorNative = calloc<interactor_native_t>();
    final configuration = InteractorDefaults.worker();
    final nativeConfiguration = arena<interactor_native_configuration_t>();
    nativeConfiguration.ref.ring_flags = configuration.ringFlags;
    nativeConfiguration.ref.ring_size = configuration.ringSize;
    nativeConfiguration.ref.buffer_size = configuration.bufferSize;
    nativeConfiguration.ref.buffers_count = configuration.buffersCount;
    nativeConfiguration.ref.cqe_peek_count = configuration.cqePeekCount;
    nativeConfiguration.ref.cqe_wait_count = configuration.cqeWaitCount;
    nativeConfiguration.ref.cqe_wait_timeout_millis = configuration.cqeWaitTimeout.inMilliseconds;
    nativeConfiguration.ref.slab_size = 65536;
    nativeConfiguration.ref.preallocation_size = 65536;
    nativeConfiguration.ref.quota_size = 128000;
    interactor.bindings.interactor_native_initialize(interactorNative, nativeConfiguration, 0);
    return interactorNative;
  });
  bindings.test_send_to_dart(native, worker.descriptor);
  producer.testSendToNative(native.ref.ring.ref.ring_fd);
  bindings.test_check(native);
  await interactor.shutdown();
}
