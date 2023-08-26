
class InteractorInitializationException implements Exception {
  final String message;

  InteractorInitializationException(this.message);

  @override
  String toString() => message;
}
