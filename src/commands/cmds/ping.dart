part of commands;

class Ping {
  static Future<bool> preRunChecks(CommandContext ctx) async {
    if(ctx.guild == null) return false;

    Member? botMember = ctx.guild!.selfMember;
    if(botMember == null) {
      botMember = await ctx.guild!.fetchMember(ctx.client.self.id);
    }
    GuildChannel channel = ctx.channel as GuildChannel;
    var botPerms = await channel.effectivePermissions(botMember);

    if(botPerms.sendMessages) {
      return true;
    }
    return false;
  }

  Future<void> commandFunction(CommandContext ctx, String msg) async {
    Stopwatch timer = Stopwatch();
    timer.start();
    AllowedMentions _mentions = AllowedMentions()..allow(reply: false);
    var msg = await ctx.reply(MessageBuilder.content("Pinging...")
      ..allowedMentions = _mentions);
    timer.stop();
    msg.edit(MessageBuilder.content(":stopwatch: Pong! `${timer.elapsedMilliseconds}ms`")
      ..allowedMentions = _mentions);
  }
}
