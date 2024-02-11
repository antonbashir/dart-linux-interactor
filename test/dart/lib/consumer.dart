import 'dart:ffi';

import 'package:linux_interactor/interactor/bindings.dart';
import 'package:linux_interactor/interactor/declaration.dart';

class TestNativeConsumer implements InteractorConsumer {
  void Function(Pointer<interactor_message> message) _checker;

  TestNativeConsumer(this._checker);

  void test(Pointer<interactor_message> message) => _checker(message);

  @override
  List<InteractorCallback> callbacks() => [test];
}
