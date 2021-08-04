class InvalidRoleException implements Exception {
  final String message;

  InvalidRoleException(this.message);

  @override 
  String toString() => message;
}
