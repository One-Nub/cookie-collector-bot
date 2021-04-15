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
    if(message.startsWith(" ")) {
      message = message.replaceFirst(" ", "");
    }
    message = message.replaceFirst(ctx.commandMatcher, "");
    //Only check for empty message since this does not need to be triggered in guild context.
    if (message == "" && isRequired) {
      throw MissingArgumentException();
    }
    else if(message == "" && !isRequired) {
      throw ArgumentNotRequiredException();
    }

    message = message.trim();
    int userID = 0;

    if (pipeDelimiterExpected && message.contains("|")) {
      message = message.split("|").first.trim();
    }
    else if (pipeDelimiterExpected && isRequired && !_rawIDRegex.hasMatch(message)) {
      throw MissingArgumentException("When searching for a user a `|` is expected.");
    }

    //If a noticeable ID can't be found & (want to search names & the guild exists)...
    if (!_rawIDRegex.hasMatch(message) &&
        (searchMemberNames && ctx.guild != null)) {

      //Remove discriminator if it exists - search methods don't like discrim
      RegExp rmvDiscrim = new RegExp(r"#\d{4}");
      if(rmvDiscrim.hasMatch(message)) {
        int matchPos = message.lastIndexOf(rmvDiscrim);
        message = message.replaceRange(matchPos, matchPos + 5, "");
      }

      //This doesn't work currently
      // var findMember = ctx.guild!.searchMembers(message, limit: 2);
      // Member findResult = await findMember.single;
      // userID = findResult.id.id;

      var findMember = await ctx.guild!.searchMembersGateway(message);
      List<Member> memberList = await findMember.toList();
      if(memberList.isNotEmpty) {
        Member findResult = memberList.first;
        userID = findResult.id.id;
      }
    } else {
      userID = _parseIDHelper(message) ?? 0;
    }

    //Exhausted methods above and a user could not be found.
    if (userID == 0 && isRequired) {
      throw InvalidUserException("Neither an ID nor username could be parsed from the given content.");
    }
    else if (userID == 0 && !isRequired) {
      throw ArgumentNotRequiredException();
    }

    try {
      User returnMe = await ctx.client.fetchUser(Snowflake(userID));
      return returnMe;
    } catch (exception) {
      //This should trigger if the found ID is not a user ID (aka the 'user' does not exist).
      throw InvalidUserException("A user could not be found from the given content/ID.");
    }
  }
}
