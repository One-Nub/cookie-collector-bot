class InvalidUserException implements Exception {
  final String message;

  InvalidUserException(this.message);

  @override 
  String toString() => message;
}
