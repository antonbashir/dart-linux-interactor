import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor_test/bindings.dart';

class TestNativeProducer implements InteractorProducer {
  final TestBindings _bindings;

  TestNativeProducer(this._bindings);

  late final InteractorMethod testCallNative;
  late final InteractorMethod testThreadingCallNative;

  @override
  void initialize(InteractorProducerRegistrat registrat) {
    testCallNative = registrat.register(_bindings.addresses.test_call_native);
    testThreadingCallNative = registrat.register(_bindings.addresses.test_threading_call_native);
  }
}
