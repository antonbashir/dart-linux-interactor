import 'package:linux_interactor/interactor/bindings.dart';
import 'package:linux_interactor/interactor/lookup.dart';

void main(List<String> args) {
  InteractorBindings(InteractorLibrary.load().library).interactor_initialize();
  print("test");
}
