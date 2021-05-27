part of commands;

class Stats {
  late AllowedMentions _mentions;
  CCDatabase _database;

  Stats(CCDatabase this._database) {
    _mentions = AllowedMentions()..allow(reply: false);
  }

  static bool preRunChecks(CommandContext ctx) {
    if(ctx.guild == null) {
      return false;
    }
    return true;
  }

  Future<void> argumentParser(CommandContext ctx, String message) async {
    var userArg = UserArgument(searchMemberNames: true);
    User user;
    try {
      user = await userArg.parseArg(ctx, message);
    }
    on ArgumentNotRequiredException {
      user = await ctx.client.fetchUser(ctx.author.id);
    }
    on InvalidUserException catch (e) {
      ctx.reply(MessageBuilder.content(e.toString())..allowedMentions = _mentions);
      return;
    }

    commandFunction(ctx, message, user);
  }

  Future<void> commandFunction(CommandContext ctx, String message, User user) async {
    var userRow = await _database.getRankedUserGuildData(user.id.id, ctx.guild!.id.id);
    Map<String, dynamic> userMap = {
      "user_id" : user.id,
      "cookies" : 0,
      "row_num" : "N/A"
    };
    if(userRow != null) {
      userMap = userRow.fields;
    }

    EmbedBuilder statsEmbed = EmbedBuilder()
      ..addField(name: "**Cookies**", content: userMap["cookies"], inline: true)
      ..addField(name: "**Rank**", content: userMap["row_num"], inline: true)
      ..color = DiscordColor.fromHexString("87CEEB")
      ..description = (userRow == null)
          ? "**This user does not have any data stored in the database for this server!**" : ""
      ..thumbnailUrl = user.avatarURL(format: "png", size: 512)
      ..timestamp = DateTime.now().toUtc()
      ..title = "${user.tag}'s Stats";

    ctx.reply(MessageBuilder.embed(statsEmbed)..allowedMentions = _mentions);
  }
}
