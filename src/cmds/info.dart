part of commands;

@Restrict(requiredContext: ContextType.guild)
@Command("info", aliases: ["status"])
Future<void> info(CommandContext ctx) async {
  var botName = "${bot.self.username + "#" + bot.self.discriminator}";
  var memUsage = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);

  //Don't you love string manip?
  String temp = bot.uptime.toString();
  var splittedTemp = temp.split(":");
  var uptime = "${splittedTemp[0]}h "
      "${splittedTemp[1]}m "
      "${splittedTemp[2].substring(0, 2)}s";

  var embed = await EmbedBuilder()
    ..addField(name: "Uptime", content: uptime, inline: true)
    //Big thanks to lib dev (l7ssha) and the power of ctrl + f for memory usage
    ..addField(
        name: "DartVM memory usage", content: "$memUsage MB", inline: true)
    ..addField(
        name: "Guild count", content: "${bot.guilds.count}", inline: true)
    ..addField(name: "User count", content: "${bot.users.count}", inline: true)
    ..addField(name: "Prefix", content: prefixHandler.prefix, inline: true)
    ..addField(name: "Creator", content: "Nub#8399", inline: true)
    ..addAuthor((author) {
      author.name = botName;
      author.iconUrl = bot.self.avatarURL();
    });
  embed.color = DiscordColor.fromHexString("87CEEB");
  embed.timestamp = DateTime.now().toUtc();
  await ctx.reply(embed: embed);
}
