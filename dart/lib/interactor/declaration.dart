import 'dart:ffi';

import 'package:linux_interactor/interactor/bindings.dart';

abstract interface class NativeConsumerDeclaration {
  List<NativeCallbackDeclaration> callbacks();
}

class NativeCallbackDeclaration {
  final void Function(Pointer<interactor_message_t> message) callback;

  NativeCallbackDeclaration(this.callback);
}

abstract interface class NativeServiceDeclaration {
  List<NativeMethodDeclaration> methods();
}

class NativeMethodDeclaration {
  final void Function(Pointer<interactor_message_t> message) method;

  NativeMethodDeclaration(this.method);
}
