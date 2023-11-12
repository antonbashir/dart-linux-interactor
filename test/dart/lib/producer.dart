import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor/interactor/producer.dart';
import 'package:linux_interactor_test/bindings.dart';

class TestNativeProducer implements NativeProducer {
  final TestBindings _bindings;
  TestNativeProducer(this._bindings);

  late final NativeMethodExecutor testCallNative;

  @override
  void initialize(NativeProducerExecutor executor) {
    testCallNative = executor.register(_bindings.addresses.test_call_native);
  }
}
