part of commands;

@Restrict(requiredContext: ContextType.guild)
@Command("leaderboard", aliases: ["lb"])
Future<void> leaderboard(CommandContext ctx) async {
  //This could be a dynamic parameter if I implement multiple retrievals
  Iterator test = await db.get_rows(ctx.guild.id.toInt(), "available_cookies");
  String output = "";
  int count = 1;
  while(test.moveNext()) {
    Map rowVals = test.current.fields;
    User user = await bot.getUser(Snowflake(rowVals['user_id']));
    output += "**$count.** $user - `${rowVals['available_cookies']}`\n";   
    count++;
  }
  var lbEmbed = EmbedBuilder()
    ..addFooter((footer) {
      footer.iconUrl = ctx.author.avatarURL();
      footer.text = "Ran by: ${ctx.author.username}#${ctx.author.discriminator}";
    });
  lbEmbed.color = DiscordColor.fromHexString("87CEEB");
  lbEmbed.description = output;
  lbEmbed.thumbnailUrl = ctx.guild.iconURL();
  lbEmbed.timestamp = DateTime.now().toUtc();
  lbEmbed.title = "Leaderboard";

  ctx.message.reply(embed: lbEmbed, mention: false);
}