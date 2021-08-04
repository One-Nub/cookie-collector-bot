part of commands;

class Generate {
  late AllowedMentions _mentions;
  CCDatabase _database;
  Generate(this._database) {
    _mentions = AllowedMentions()..allow(reply: false);
  }

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
    var userArg = UserArgument(searchMemberNames: true, pipeDelimiter: true, isRequired: true);
    User user;
    try {
      user = await userArg.parseArg(ctx, message);
    }
    on MissingArgumentException catch (e) {
      ctx.reply(MessageBuilder.content("$e \nThis command requires `[user] [amount]`")
        ..allowedMentions = _mentions);
      return;
    }
    on InvalidUserException catch (e) {
      ctx.reply(MessageBuilder.content(e.toString())
        ..allowedMentions = _mentions);
      return;
    }

    //Remove content before pipe when it exists
    //Pipe is required when searching via username
    message = message.split("|").last;
    List<String> args = message.split(" ").toList();
    if(args.isEmpty) {
      ctx.reply(MessageBuilder.content("An amount of cookies to generate was expected.")
        ..allowedMentions = _mentions);
      return;
    }
    int? cookieCnt = int.tryParse(args.last);
    if(cookieCnt == null || cookieCnt == user.id.id) {
      ctx.reply(MessageBuilder.content("An amount of cookies to generate was expected.")
        ..allowedMentions = _mentions);
      return;
    }

    commandFunction(ctx, message, user, cookieCnt);
  }

  Future<void> commandFunction(CommandContext ctx, String msg, User user, int cookieCnt) async {
    Message confirmPrompt = await ctx.reply(MessageBuilder.content(
      "Please verify your intentions: `${user.tag}` will recieve `${cookieCnt}` cookies")
      ..allowedMentions = _mentions);

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
      await ctx.reply(MessageBuilder.content("Cancelled due to timeout.")
        ..allowedMentions = _mentions);
    }
    else if(result.emoji.encodeForAPI() == confirm.encodeForAPI()) {
      await confirmPrompt.deleteSelfReaction(deny);
      await _database.addCookies(user.id.id, cookieCnt, ctx.guild!.id.id);
      await confirmPrompt.edit(MessageBuilder.content("Done - `${user.tag}` has recieved "
        "`$cookieCnt` cookies.")
        ..allowedMentions = _mentions);
    }
    else {
      confirmPrompt.deleteSelfReaction(confirm);
      await confirmPrompt.edit(MessageBuilder.content("Cancelled - `${user.tag}`'s cookies "
        "have not been modified.")
        ..allowedMentions = _mentions);
    }
  }
}
