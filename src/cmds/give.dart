part of commands;

@UserProcessor()
@Restrict(requiredContext: ContextType.guild, cooldown: 10)
@Command("give", aliases: ["donate", "transfer"])
Future<void> give(CommandContext ctx, [User reciever, int cookieCount]) async {
  if(reciever is int) {
    reciever = ctx.guild.members[Snowflake(reciever)];
  }

  if (cookieCount == null) {
    ctx.reply(content: "${ctx.author.mention} I need an amount of cookies to give!");
    return;
  }
  else if(cookieCount <= 0) { // || if userCookieCount < cookieCount
    ctx.reply(content: "${ctx.author.mention} You can't give that many cookies!");
    return;
  }

  //Here i'll put the method(s) to alter the giver's cookie count & reciever's cc.

  ctx.message.delete();
  var giveEmbed = EmbedBuilder()
    ..title = "How generous! :cookie:"
    ..description = "${ctx.author.mention} gave ${reciever.mention} $cookieCount cookies!";
  ctx.reply(embed: giveEmbed);
}
