import 'dart:ffi';

import 'bindings.dart';

abstract interface class InteractorChannelRegistrat {
  List<void Function(Pointer<interactor_message_t> message)> get operations;
}
