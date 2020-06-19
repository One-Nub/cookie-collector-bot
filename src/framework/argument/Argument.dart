part of framework;

/// Searches string for numbers between < and >, while ignoring proceeding characters in-between 
/// < & > before the numbers.
final RegExp _mentionIDRegex = RegExp("<.+\?(\\d+)>");

/// Searches for any numbers with more than the expected minimum length a discord ID
/// can be, which is 17 characters.
final RegExp _rawIDRegex = RegExp("(\\d{17,})");

/// Basis for argument parsing classes
abstract class Argument<T> {
  late bool pipeDelimiterExpected;
  late bool isRequired;

  Argument([this.pipeDelimiterExpected = false, this.isRequired = false]);

  /// Forced to be overidden by subclasses due to dynamic nature.
  /// 
  /// Message being passed should already have proceeding content removed, such as
  /// the command trigger & any other arguments.
  T? parseArg(CommandContext ctx, String message);

  /// Gets ID out of a given input.
  /// 
  /// Returns a supposed valid discord ID parsed from the content. Null if nothing
  /// could be parsed from the input.
  int? _parseIDHelper(String message) {
    // Type casting for match groups should work since a valid match was already found.
    if(_mentionIDRegex.hasMatch(message)) {
      Match? match = _mentionIDRegex.firstMatch(message);
      return int.tryParse(match!.group(1) as String);
    } 
    else if (_rawIDRegex.hasMatch(message)) {
      Match? match = _rawIDRegex.firstMatch(message);
      return int.tryParse(match!.group(0) as String);
    }
    else return null; //Nothing considered an ID could be found.
  }
}
