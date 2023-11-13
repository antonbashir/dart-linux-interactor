import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor/interactor/message.dart';

class TestNativeConsumer implements NativeConsumer {
  void Function(InteractorNotification message) _checker;

  TestNativeConsumer(this._checker);

  void test(InteractorNotification message) => _checker(message);

  @override
  List<NativeCallback> callbacks() => [NativeCallback(test)];
}
