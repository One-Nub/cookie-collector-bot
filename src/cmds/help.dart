part of commands;

@Command("help")
Future<void> help(CommandContext ctx) async {
  String commands =
    "`.daily` ➙ collect a set amount of cookies once a day\n"
    "`.eat` ➙ eat a cookie! that's literally it\n"
    "`.give <user> <amt>` ➙ give the user of your choosing some cookies\n"
    "`.help` ➙ view this help prompt!\n"
    "`.info` ➙ get some information about the bot\n"
    "`.leaderboard` ➙ view the top 15 people with the most cookies\n"
    "`.ping` ➙ view the latency between discord and the bot\n"
    "`.rob <user>` ➙ take some cookies from someone\n"
    "`.stats [user]` ➙ view your stored cookie count and level, or someone elses";

  StringBuffer buffer = new StringBuffer();
  buffer.write("`.say <channel> <message>` ➙ have the bot say something in a channel\n");
  if (await ctx.author.id.toInt() == 156872400145874944) {
    buffer.write("`.generate <user> <amt>` ➙ give the user infinite cookies\n");
  }

  var helpEmbed = await EmbedBuilder()
    ..addField(name: "Commands", content: commands);
  if (admins.contains(ctx.author.id)) {
    await helpEmbed.addField(name: "Admin Commands", content: buffer.toString());
  }

  helpEmbed.title = "Help!";
  helpEmbed.description = "Welcome to the help prompt! Hopefully you find what "
    "you are looking for! \n\n If you happen to find a bug of some sort, "
    "please DM Nub#8399 and he will look into it!";

  var authorDM = await ctx.author.dmChannel;
  if(ctx.channel is DMChannel) {
    ctx.channel.send(embed: helpEmbed);
  }
  else {
    await ctx.message.reply(content: "please check your DMs!");
    await authorDM.send(embed: helpEmbed);
  }
}
