part of commands;

class Info {
  Future<void> commandFunction(CommandContext ctx, String msg) async {
    String memUsage = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
    DateTime startTime = DateTime.now().subtract(ctx.client.uptime);
    String runtime = DateTimeFormat.relative(startTime, levelOfPrecision: 5, abbr: true);

    String prefix;
    if(ctx.guild == null) {
      prefix = ".";
    }
    else {
      //TODO: Get prefix from database
      prefix = ".";
    }

    var embed = await EmbedBuilder()
      ..addField(name: "Uptime", content: runtime, inline: true)
      ..addField(name: "Memory Usage", content: "$memUsage MB", inline: true)
      ..addField(name: "Version", content: "v1.0.1", inline: true)
      ..addField(name: "(Cached) Guilds", content: ctx.client.guilds.count, inline: true)
      ..addField(name: "(Cached) Users", content: ctx.client.users.count, inline: true)
      ..addField(name: "Prefix", content: prefix, inline: true)
      ..addField(name: "Creator", content: "Nub#8399", inline: true)
      ..addAuthor((author) {
        author.name = ctx.client.self.tag;
        author.iconUrl = ctx.client.self.avatarURL(format: "png");
      })
      ..timestamp = DateTime.now().toUtc()
      ..color = DiscordColor.fromHexString("87CEEB");

    await ctx.reply(embed: embed);
  }
}
