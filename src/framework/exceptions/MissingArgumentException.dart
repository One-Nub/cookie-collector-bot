part of framework;

class MissingArgumentException implements Exception{
  @override 
  String toString() => "No arguments could be found in the given message.";
}