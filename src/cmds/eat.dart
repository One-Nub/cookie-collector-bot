part of commands;

@Restrict(requiredContext: ContextType.guild)
@Command("eat", aliases: ["nom"])
Future<void> eat(CommandContext ctx) async {
  int userID = ctx.author.id.toInt();
  int guildID = ctx.guild.id.toInt();
  await db.remove_cookies(userID, 1, guildID);
  await ctx.message.reply(content: "You ate 1 cookie! very yummy :cookie:");
}
