part of commands;

class Give {
  CCDatabase _database;
  Give(this._database);

  static Future<bool> preRunChecks(CommandContext ctx, CCDatabase _database) async {
    if(ctx.guild == null) return false;

    int userCookies = await _database.getCookieCount(ctx.author.id.id, ctx.guild!.id.id);
    if(userCookies <= 0) {
      ctx.reply(content: "You at least need *a* cookie before you can give some away");
      return false;
    }

    return true;
  }

  Future<void> argumentParser(CommandContext ctx, String msg) async {
    msg = msg.replaceFirst(" ", "");
    msg = msg.replaceFirst(ctx.commandMatcher, "");
    UserArgument recipientArg = UserArgument(isRequired: true);
    User recipient;
    try {
      recipient = await recipientArg.parseArg(ctx, msg);
    }
    on MissingArgumentException catch (e) {
      ctx.reply(content: "$e \nThis command requires `[user] [amount]`");
      return;
    }
    on InvalidUserException catch (e) {
      ctx.reply(content: e);
      return;
    }

    if(recipient.id == ctx.author.id) {
      ctx.reply(content: "You can't give cookies to yourself... Right?");
      return;
    }

    List<String> args = msg.split(" ").toList();
    if(args.isEmpty) {
      ctx.reply(content: "An amount of cookies to give was expected.");
      return;
    }

    int? cookiesToGive = int.tryParse(args.last);
    int userCookies = await _database.getCookieCount(ctx.author.id.id, ctx.guild!.id.id);
    if(cookiesToGive == null || cookiesToGive == recipient.id.id) {
      ctx.reply(content: "An amount of cookies to give was expected.");
      return;
    }
    else if(cookiesToGive <= 0 || cookiesToGive > userCookies) {
      ctx.reply(content: "You can't give that amount of cookies!");
      return;
    }

    commandFunction(ctx, msg, recipient, cookiesToGive);
  }

  Future<void> commandFunction(CommandContext ctx, String msg, User recipient, int cookieCnt) async {
    if(cookieCnt >= 50)
    {
      var botConfirm = await ctx.reply(content: "Please confirm that you want to send"
      " **${recipient.tag}** `$cookieCnt` cookies. (`Yes/No`)");

      var userConfirmStream = await ctx.nextMessagesWhere(
        (msg) => msg.message.author.id == (ctx.author.id), limit: 1);

      MessageReceivedEvent userConfirm = await userConfirmStream.first;
      if(!userConfirm.message.content.toLowerCase().startsWith("y")) {
        var cancelMsg = await ctx.reply(content: "Cancelled.");
        botConfirm.delete();
        ctx.message.delete();
        await Future.delayed(Duration(seconds: 3));
        cancelMsg.delete();
        return;
      }

      botConfirm.delete();
      userConfirm.message.delete();
    }

    await _database.addCookies(recipient.id.id, cookieCnt, ctx.guild!.id.id);
    await _database.removeCookies(ctx.author.id.id, cookieCnt, ctx.guild!.id.id);

    User authorUser = await ctx.client.fetchUser(ctx.author.id);
    
    var giveEmbed = EmbedBuilder()
      ..title = "How generous! :cookie:"
      ..description = "${authorUser.mention} gave ${recipient.mention} $cookieCnt cookies!";
    ctx.reply(embed: giveEmbed);
  }
}
