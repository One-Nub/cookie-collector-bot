class InvalidChannelException implements Exception {
  final String message;

  InvalidChannelException(this.message);

  @override 
  String toString() => message;
}
