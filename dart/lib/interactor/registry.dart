import 'dart:ffi';

import 'operation.dart';
import 'bindings.dart';
import 'service.dart';
import 'registrat.dart';

class InteractorChannelRegistry {
  final _channels = <NativeService>[];

  void register(InteractorChannelRegistrat registrat) {
    final operations = <NativeFunction>[];
    for (var operation in registrat.operations) {
      operations.add(NativeFunction(operations.length, operation));
    }
    _channels.add(NativeService(
      _channels.length,
      _workerPointer,
      _bindings,
      _buffers,
      operations,
    ));
  }

  void execute(Pointer<interactor_message_t> message) => _channels[message.ref.channel_id].execute(message);
}
