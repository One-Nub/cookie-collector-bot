part of commands;

class Say {
  static Future<bool> preRunChecks(CommandContext ctx, List<Snowflake> admins) async {
    if(ctx.guild == null) {
      return false;
    }

    if(admins.contains(ctx.author.id)) {
      return true;
    }

    Member user = await ctx.guild!.fetchMember(ctx.author.id);
    Permissions userPerms = await user.effectivePermissions;
    if(userPerms.administrator || userPerms.manageGuild) {
      return true;
    }
    return false;
  }

  Future<void> argumentParser(CommandContext ctx, String message) async {
    ChannelArgument cArg = ChannelArgument<TextGuildChannel>();
    TextGuildChannel channel;
    try {
      channel = await cArg.parseArg(ctx, message) as TextGuildChannel;
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
    TextGuildChannel textChannel) async {
      Member? botMember = ctx.guild!.selfMember;
      if(botMember == null) {
        botMember = await ctx.guild!.fetchMember(ctx.client.self.id);
      }
      var botSendPerm =
        await textChannel.effectivePermissions(botMember);
      if(botSendPerm.sendMessages && botSendPerm.viewChannel) {
        textChannel.sendMessage(content: message);
      }
      else {
        ctx.reply(content: "I can't send messages in that channel! <a:confuse:724785215838617770>");
      }
  }
}
