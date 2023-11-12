class InteractorInitializationException implements Exception {
  final String message;

  InteractorInitializationException(this.message);

  @override
  String toString() => message;
}

class InteractorOutOfMemory implements Exception {
  final String message;

  InteractorOutOfMemory() : this.message = StackTrace.current.toString();

  @override
  String toString() => "Out of memory:\n${message}";
}
