/// Searches the start of string for numbers between < and >, while ignoring
/// proceeding characters in-between < & > before the numbers.
final RegExp mentionIDRegex = RegExp("^<.+\?(\\d+)>");

/// Searches for any numbers at the start of the string
/// with more than the expected minimum length a discord ID can be,
/// which is 17 characters.
final RegExp rawIDRegex = RegExp("(\\d{17,})");

int? parseID(String input) {
  // Type casting for match groups should work since a valid match was already found.
  if (mentionIDRegex.hasMatch(input)) {
    Match? match = mentionIDRegex.firstMatch(input);
    return int.tryParse(match!.group(1) as String);
  } else if (rawIDRegex.hasMatch(input)) {
    Match? match = rawIDRegex.firstMatch(input);
    return int.tryParse(match!.group(0) as String);
  } else
    return null; //Nothing considered an ID could be found.
}
