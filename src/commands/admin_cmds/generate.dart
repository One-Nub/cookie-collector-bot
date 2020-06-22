part of commands;

class Generate {
  CCDatabase _database;
  Generate(this._database);

  static bool preRunChecks(CommandContext ctx) {
    //Must be run in guild & must be me
    if(ctx.guild == null || ctx.author!.id.id != 156872400145874944) {
      return false;
    }
    return true;
  }

  Future<void> argumentParser(CommandContext ctx, String message) async {
    message = message.replaceFirst(" ", "");
    message = message.replaceFirst(ctx.commandMatcher, "");
    var userArg = UserArgument(searchMemberNames: true, pipeDelimiter: true);
    User user;
    try {
      user = await userArg.parseArg(ctx, message);
    }
    on MissingArgumentException catch (e) {
      ctx.reply(content: e);
      return;
    }
    on InvalidUserException catch (e) {
      ctx.reply(content: e);
      return;
    }

    //Remove content before pipe when it exists
    //Pipe is required when searching via username
    message = message.split("|").last;
    List<String> args = message.split(" ").toList();
    if(args.isEmpty) {
      ctx.reply(content: "An amount of cookies to generate was expected.");
      return;
    }
    int? cookieCnt = int.tryParse(args.last);
    if(cookieCnt == null) {
      ctx.reply(content: "An amount of cookies to generate was expected.");
      return;
    }

    commandFunction(ctx, message, user, cookieCnt);
  }

  Future<void> commandFunction(CommandContext ctx, String msg, User user, int cookieCnt) async {
    var confirmPrompt = await ctx.reply(content:
      "Please verify your intentions: `${user.tag}` will recieve `${cookieCnt}` cookies");
    final emoteGuild = await ctx.client.getGuild(Snowflake(440350951572897812));
    final confirm = await emoteGuild.getEmoji(Snowflake(724438115791667220));
    final deny = await emoteGuild.getEmoji(Snowflake(724438115384557579));

    Duration emoteDelay = Duration(milliseconds: 250);
    await Future.delayed(emoteDelay, () => confirmPrompt.createReaction(confirm));
    await Future.delayed(emoteDelay, () => confirmPrompt.createReaction(deny));

    MessageReactionEvent? reactionStream = await ctx.client.onMessageReactionAdded
    .firstWhere((element) {
      return element.userId == ctx.author!.id &&
        (element.emoji == confirm || element.emoji == deny);
    })
    .timeout(Duration(seconds: 15))
    .catchError((event) {
      return null;
    });

    var result = await reactionStream;
    if(result == null) {
      confirmPrompt.deleteReaction(confirm);
      await ctx.reply(content: "Cancelled due to timeout.");
    }
    else if(result.emoji == confirm) {
      await confirmPrompt.deleteReaction(deny);
      await _database.addCookies(user.id.id, cookieCnt, ctx.guild!.id.id);
      await confirmPrompt.edit(content: "Done - `${user.tag}` has recieved "
        "`$cookieCnt` cookies.");
    }
    else {
      confirmPrompt.deleteReaction(confirm);
      await confirmPrompt.edit(content: "Cancelled - `${user.tag}`'s cookies "
        "have not been modified.");
    }
  }
}
