import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor_test/bindings.dart';

class TestNativeProducer extends NativeProducer {
  final TestBindings _bindings;
  TestNativeProducer(this._bindings);

  late final testCallNative = synchronous(_bindings.addresses.test_call_native);

  @override
  List<NativeMethod> methods() => [NativeMethod(_bindings.addresses.test_call_native)];
}
