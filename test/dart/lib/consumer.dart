import 'package:linux_interactor/interactor/declaration.dart';
import 'package:linux_interactor/interactor/notifications.dart';

class TestNativeConsumer implements InteractorConsumer {
  void Function(InteractorNotification message) _checker;

  TestNativeConsumer(this._checker);

  void test(InteractorNotification message) => _checker(message);
  
  Future<void> test2(InteractorNotification message) async => _checker(message);

  @override
  List<InteractorCallback> callbacks() => [test, test2];
}
