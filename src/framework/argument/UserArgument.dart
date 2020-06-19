part of framework;

/// Facilitates the ability of getting a User from a passed input.
/// 
/// Throws [MissingArgumentException] if an argument cannot be found.
/// Throws [InvalidUserException] when a valid user cannot be found.
class UserArgument extends Argument {
  late bool searchMemberNames;

  UserArgument(
      {bool pipeDelimiter = false,
      this.searchMemberNames = false,
      bool isRequired = false})
      : super(pipeDelimiter, isRequired);


  @override
  Future<User> parseArg(CommandContext ctx, String message) async {
    //Only check for empty message since this does not need to be triggered in guild context.
    if (message == "") {
      throw MissingArgumentException();
    }

    message = message.trim();
    int userID = 0;

    if (pipeDelimiterExpected && message.contains("|")) {
      message = message.split("|").first.trim();
    }

    //If a noticeable ID can't be found & (want to search names & the guild exists)...
    if (!_rawIDRegex.hasMatch(message) &&
        (searchMemberNames && ctx.guild != null)) {
      //Attempt to search member cache for a username containing the string, or
      //for a member tag username#discrim that matches the message.
      List<IMember> cachedMembers = ctx.guild!.members.values.toList();
      for (var member in cachedMembers) {
        if (member.username.startsWith(message) || member.tag == message) {
          userID = member.id.id;
          break;
        }
      }
    } else {
      userID = _parseIDHelper(message) ?? 0;
    }

    //Exhausted methods above and a user could not be found.
    if (userID == 0) {
      throw InvalidUserException("Neither an ID nor username could be parsed from the given content.");
    }

    try {
      User returnMe = await ctx.client.getUser(Snowflake(userID)) as User;
      return returnMe;
    } catch (exception) {
      //This should trigger if the found ID is not a user ID (aka the 'user' does not exist).
      throw InvalidUserException("A user could not be found from the given content/ID.");
    }
  }
}
