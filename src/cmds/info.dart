part of commands;

@Restrict(requiredContext: ContextType.guild)
@Command("info", aliases: ["status"])
Future<void> info(CommandContext ctx) async {
  String botName = "${bot.self.username + "#" + bot.self.discriminator}";
  String memUsage = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);

  var startTime = DateTime.now().subtract(bot.uptime);
  startTime = startTime.subtract(Duration(hours: 892, minutes: 30));
  var runtime = DateTimeFormat.relative(startTime, levelOfPrecision: 5, abbr: true);

  var embed = await EmbedBuilder()
    ..addField(name: "Uptime", content: runtime, inline: true)
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
