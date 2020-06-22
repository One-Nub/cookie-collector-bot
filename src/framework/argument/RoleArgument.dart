part of framework;

/// Facilitates the ability of getting a Role from a passed input.
/// 
/// Throws [GuildContextRequiredException] when run from a non-guild context.
/// Throws [MissingArgumentException] if an argument cannot be found.
/// Throws [InvalidRoleException] when a matching role cannot be found.
class RoleArgument extends Argument {
  late bool searchRoleNames;

  RoleArgument(
      {bool pipeDelimiter = false,
      this.searchRoleNames = false,
      bool isRequired = false})
      : super(pipeDelimiter, isRequired);

  @override
  Role parseArg(CommandContext ctx, String message) {
    if (ctx.guild == null) {
      throw GuildContextRequiredException();
    }

    message = message.replaceFirst(" ", "");
    message = message.replaceFirst(ctx.commandMatcher, "");
    if(message == "") {
      throw MissingArgumentException();
    }

    message = message.trim();
    int roleID = 0;

    if (pipeDelimiterExpected && message.contains("|")) {
      message = message.split("|").first.trim();
    }

    if (_rawIDRegex.hasMatch(message)) {
      roleID = _parseIDHelper(message) ?? 0;
      if (roleID == 0) {
        throw InvalidRoleException("An ID could not be found in the given message.");
      }
    }

    List<IRole> cachedGuildRoles = ctx.guild!.roles.values.toList();
    for (var role in cachedGuildRoles) {
      role = role as Role;
      if (roleID == role.id.id) {
        return role;
      } else if (searchRoleNames && role.name == message) {
        return role;
      }
    }

    //A matching role could not be found (in the cache)
    throw InvalidRoleException("A matching role could not be found from the given message.");
  }
}
