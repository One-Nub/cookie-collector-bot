part of commands;

class Generate {
  CCDatabase _database;
  Generate(this._database);

  static bool preRunChecks(CommandContext ctx) {
    //Must be run in guild & must be me
    if(ctx.guild == null || ctx.author.id.id != 156872400145874944) {
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
      ctx.reply(content: "$e This command requires `[user] [amount]`");
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
    if(cookieCnt == null || cookieCnt == user.id.id) {
      ctx.reply(content: "An amount of cookies to generate was expected.");
      return;
    }

    commandFunction(ctx, message, user, cookieCnt);
  }

  Future<void> commandFunction(CommandContext ctx, String msg, User user, int cookieCnt) async {
    Message confirmPrompt = await ctx.reply(content:
      "Please verify your intentions: `${user.tag}` will recieve `${cookieCnt}` cookies");

    // final emoteGuild = await ctx.client.fetchGuild(Snowflake(440350951572897812));
    // final confirm = await emoteGuild.fetchEmoji(Snowflake(724438115791667220));
    // final deny = await emoteGuild.fetchEmoji(Snowflake(724438115384557579));
    UnicodeEmoji confirm = UnicodeEmoji("✅");
    UnicodeEmoji deny = UnicodeEmoji("❎");

    Duration emoteDelay = Duration(milliseconds: 250);
    await Future.delayed(emoteDelay, () => confirmPrompt.createReaction(confirm));
    await Future.delayed(emoteDelay, () => confirmPrompt.createReaction(deny));

    MessageReactionEvent? reactionStream = await ctx.client.onMessageReactionAdded
    .firstWhere((element) {
      return element.user.id == ctx.author.id &&
        (element.emoji.encodeForAPI() == confirm.encodeForAPI()
        || element.emoji.encodeForAPI() == deny.encodeForAPI());
    })
    .timeout(Duration(seconds: 15))
    .catchError((event) {
      return null;
    });

    MessageReactionEvent? result = await reactionStream;
    if(result == null) {
      await confirmPrompt.delete();
      await ctx.reply(content: "Cancelled due to timeout.");
    }
    else if(result.emoji.encodeForAPI() == confirm.encodeForAPI()) {
      await confirmPrompt.deleteSelfReaction(deny);
      await _database.addCookies(user.id.id, cookieCnt, ctx.guild!.id.id);
      await confirmPrompt.edit(content: "Done - `${user.tag}` has recieved "
        "`$cookieCnt` cookies.");
    }
    else {
      confirmPrompt.deleteSelfReaction(confirm);
      await confirmPrompt.edit(content: "Cancelled - `${user.tag}`'s cookies "
        "have not been modified.");
    }
  }
}
