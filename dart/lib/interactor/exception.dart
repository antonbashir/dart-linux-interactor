class InteractorInitializationException implements Exception {
  final String message;

  InteractorInitializationException(this.message);

  @override
  String toString() => message;
}

class InteractorRuntimeException implements Exception {
  final String message;

  InteractorRuntimeException(this.message);

  @override
  String toString() => message;
}
