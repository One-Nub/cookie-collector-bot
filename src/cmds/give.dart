part of commands;

@UserProcessor()
@Restrict(requiredContext: ContextType.guild)
@Command("give", aliases: ["donate", "transfer"])
Future<void> give(CommandContext ctx, [User reciever, int cookieCount]) async {
  if(reciever is int) {
    reciever = ctx.guild.members[Snowflake(reciever)];
  }

  if(reciever.id == ctx.author.id) {
    await ctx.message.reply(content: "You can't give yourself cookies, that's called"
    " either buying or baking them.");
    return;
  }

  int authorCookieCount = await db.get_cookies(ctx.author.id.toInt(), ctx.guild.id.toInt());
  if (cookieCount == null) {
    ctx.reply(content: "${ctx.author.mention} I need an amount of cookies to give!");
    return;
  }
  else if(cookieCount <= 0 || cookieCount > authorCookieCount) {
    ctx.reply(content: "${ctx.author.mention} You can't give that many cookies!");
    return;
  }

  if(cookieCount >= 50)
  {
    var botConfirm = await ctx.reply(content: "Please confirm that you want to send"
    " **${reciever.tag}** `$cookieCount cookies`. (`Yes/No`)");

    var userConfirmStream = await ctx.nextMessagesWhere(
      (msg) => msg.message.author.id == (ctx.author.id), limit: 1);

    MessageEvent userConfirm = await userConfirmStream.first;
    if(!userConfirm.message.content.toLowerCase().startsWith("y")) {
      ctx.replyTemp(new Duration(seconds: 5), content: "Cancelled.");
      botConfirm.delete();
      ctx.message.delete();
      return;
    }

    botConfirm.delete();
    userConfirm.message.delete();
  }

  await db.add_cookies(reciever.id.toInt(), cookieCount, ctx.guild.id.toInt());
  await db.remove_cookies(ctx.author.id.toInt(), cookieCount, ctx.guild.id.toInt());

  ctx.message.delete();
  var giveEmbed = EmbedBuilder()
    ..title = "How generous! :cookie:"
    ..description = "${ctx.author.mention} gave ${reciever.mention} $cookieCount cookies!";
  ctx.reply(embed: giveEmbed);
}
