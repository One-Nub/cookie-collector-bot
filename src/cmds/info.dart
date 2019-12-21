part of commands;

@Command("info", typing: true, aliases: ["status", "stats"])
Future<void> info(CommandContext ctx) async {
  var botName = "${bot.self.username + "#" + bot.self.discriminator}";
  var memUsage = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
  var embed = EmbedBuilder()
    ..addField(
        name: "Uptime", content: "${bot.uptime.inMinutes} min", inline: true)
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
  ctx.message.reply(mention: false, embed: embed);
}
