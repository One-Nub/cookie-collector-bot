import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commander/commander.dart';

import 'Argument.dart';
import '../exceptions/GuildContextRequired.dart';
import '../exceptions/InvalidRoleException.dart';
import '../exceptions/MissingArgumentException.dart';

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

    if (rawIDRegex.hasMatch(message)) {
      roleID = parseIDHelper(message) ?? 0;
      if (roleID == 0) {
        throw InvalidRoleException("An ID could not be found in the given message.");
      }
    }

    List<Role> cachedGuildRoles = ctx.guild!.roles.values.toList();
    for (var role in cachedGuildRoles) {
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
