part of commands;

class Stats {
  CCDatabase _database;
  Stats(CCDatabase this._database);

  static bool preRunChecks(CommandContext ctx) {
    if(ctx.guild == null) {
      return false;
    }
    return true;
  }

  Future<void> argumentParser(CommandContext ctx, String message) async {
    message = message.replaceFirst(" ", "");
    message = message.replaceFirst(ctx.commandMatcher, "");

    var userArg = UserArgument(searchMemberNames: true);
    User user;
    try {
      user = await userArg.parseArg(ctx, message);
    }
    on MissingArgumentException {
      user = await ctx.client.getUser(ctx.author!.id) as User;
    }
    on InvalidUserException catch (e) {
      ctx.reply(content: e);
      return;
    }

    commandFunction(ctx, message, user);
  }

  Future<void> commandFunction(CommandContext ctx, String message, User user) async {
    var userRow = await _database.getStoredUserAndRank(user.id.id, ctx.guild!.id.id);
    Map<String, dynamic> userMap = {
      "user_id" : user.id,
      "available_cookies" : 0,
      "row_num" : "N/A"
    };
    if(userRow != null) {
      userMap = userRow.fields;
    }

    EmbedBuilder statsEmbed = EmbedBuilder()
      ..addField(name: "**Cookies**", content: userMap["available_cookies"], inline: true)
      ..addField(name: "**Leaderboard Position**", content: userMap["row_num"], inline: true)
      ..color = DiscordColor.fromHexString("87CEEB")
      ..description = (userRow == null)
          ? "**This user does not have any data stored in the database!**" : ""
      ..thumbnailUrl = user.avatarURL(format: "png", size: 512)
      ..timestamp = DateTime.now().toUtc()
      ..title = "${user.tag}'s Stats";

    ctx.channel.send(embed: statsEmbed);
  }
}
