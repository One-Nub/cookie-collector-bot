part of commands;

@UserProcessor()
@Restrict(requiredContext: ContextType.guild)
@Command("generate")
Future<void> generate(CommandContext ctx, [User reciever, int cookieCount]) async {
  //Limit this to only me.
  if (ctx.message.author.id.toInt() != 156872400145874944) return;

  if (reciever is int) {
    reciever = ctx.guild.members[Snowflake(reciever)];
  }

  if (cookieCount == null) {
    ctx.message.delete();
    ctx.replyTemp(Duration(seconds: 3),
        content: "${ctx.author.mention} I need an amount of cookies to give!");
    return;
  }

  await db.add_cookies(reciever.id.toInt(), cookieCount, ctx.guild.id.toInt());
  await ctx.replyTemp(Duration(seconds: 3), content: "Success.");
  await ctx.message.delete();
}
