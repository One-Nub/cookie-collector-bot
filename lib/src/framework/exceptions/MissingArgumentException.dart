class MissingArgumentException implements Exception{
  final String message;

  MissingArgumentException([this.message = "No arguments could be found in the given message."]);

  @override
  String toString() => message;
}
