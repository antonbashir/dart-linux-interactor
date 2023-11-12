import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor/interactor/message.dart';

class TestNativeConsumer implements NativeConsumer {
  void test(InteractorNotification message) {
    print("Hello, C");
  }

  @override
  List<NativeCallback> callbacks() => [NativeCallback(test)];
}
