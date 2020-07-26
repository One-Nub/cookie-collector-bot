part of commands;

class Say {
  static Future<bool> preRunChecks(CommandContext ctx, List<Snowflake> admins) async {
    if(ctx.guild == null) {
      return false;
    }

    if(admins.contains(ctx.author!.id)) {
      return true;
    }

    CacheMember user = await ctx.guild!.getMemberById(ctx.author!.id) as CacheMember;
    if(user.effectivePermissions.administrator ||
        user.effectivePermissions.manageGuild) {
      return true;
    }
    return false;
  }

  Future<void> argumentParser(CommandContext ctx, String message) async {
    ChannelArgument cArg = ChannelArgument<CacheTextChannel>();
    CacheTextChannel channel;
    try {
      channel = await cArg.parseArg(ctx, message) as CacheTextChannel;
    }
    on MissingArgumentException catch (e) {
      ctx.reply(content: "$e A channel identifier was expected.");
      return;
    }
    on InvalidChannelException catch (e) {
      ctx.reply(content: e);
      return;
    }
    message = message.replaceFirst(" ", "").trim();
    message = message.substring(message.contains(">") ?
      message.indexOf(">") + 1 :
      message.indexOf(" "))
      .trim();

    if(message.isEmpty) {
      ctx.reply(content: "I needed something to say..");
      return;
    }
    commandFunction(ctx, message, channel);
  }

  Future<void> commandFunction(CommandContext ctx, String message,
    CacheTextChannel cacheTextChannel) async {
      var botSendPerm =
        cacheTextChannel.effectivePermissions(ctx.guild!.selfMember as CacheMember).sendMessages;
      if(botSendPerm) {
        cacheTextChannel.send(content: message);
      }
      else {
        var emojiGuild = await ctx.client.getGuild(Snowflake(440350951572897812));
        var emote = await emojiGuild.getEmoji(Snowflake(724785215838617770));
        ctx.reply(content: "I can't send messages in that channel! $emote");
      }
  }
}
