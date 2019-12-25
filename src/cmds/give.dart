part of commands;

@UserProcessor()
@Restrict(requiredContext: ContextType.guild)
@Command("give", aliases: ["donate", "transfer"])
Future<void> give(CommandContext ctx, [User reciever, int cookieCount]) async {
  if(reciever is int) {
    reciever = ctx.guild.members[Snowflake(reciever)];
  }
  
  int authorCookieCount = await db.get_cookies(ctx.author.id.toInt(), ctx.guild.id.toInt());
  
  if (cookieCount == null) {
    ctx.reply(content: "${ctx.author.mention} I need an amount of cookies to give!");
    return;
  }
  else if(cookieCount <= 0 || cookieCount > 50 || cookieCount > authorCookieCount) {
    ctx.reply(content: "${ctx.author.mention} You can't give that many cookies!");
    return;
  }

  await db.add_cookies(reciever.id.toInt(), cookieCount, ctx.guild.id.toInt());
  await db.remove_cookies(ctx.author.id.toInt(), ctx.guild.id.toInt());

  ctx.message.delete();
  var giveEmbed = EmbedBuilder()
    ..title = "How generous! :cookie:"
    ..description = "${ctx.author.mention} gave ${reciever.mention} $cookieCount cookies!";
  ctx.reply(embed: giveEmbed);
}
