import 'dart:ffi';

import 'bindings.dart';

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
  final Pointer<NativeFunction<Void Function(Pointer<interactor_message_t>)>> method;

  NativeMethodDeclaration(this.method);
}
