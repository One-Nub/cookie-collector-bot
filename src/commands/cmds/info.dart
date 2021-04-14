part of commands;

class Info {
  late CCDatabase _ccDatabase;
  Info(this._ccDatabase);

  Future<void> commandFunction(CommandContext ctx, String msg) async {
    String memUsage = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
    DateTime startTime = DateTime.now().subtract(ctx.client.uptime);
    String runtime = DateTimeFormat.relative(startTime, levelOfPrecision: 5, abbr: true);

    String prefix;
    if(ctx.guild == null) {
      prefix = ".";
    }
    else {
      prefix = await _ccDatabase.getPrefix(ctx.guild!.id.id);
    }

    var embed = await EmbedBuilder()
      ..addField(name: "Uptime", content: runtime, inline: true)
      ..addField(name: "Memory Usage", content: "$memUsage MB", inline: true)
      ..addField(name: "Nyxx Version", content: "${ctx.client.version}", inline: true)
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

    await ctx.sendMessage(embed: embed);
  }
}
