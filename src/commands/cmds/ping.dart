part of commands;

class Ping {
  static Future<bool> preRunChecks(CommandContext ctx) async {
    if(ctx.guild == null) return false;

    var botMember = ctx.guild!.selfMember as CacheMember;
    var channel = ctx.channel as CacheTextChannel;
    if(channel.effectivePermissions(botMember).sendMessages) {
      return true;
    }
    return false;
  }

  Future<void> commandFunction(CommandContext ctx, String msg) async {
    Stopwatch timer = Stopwatch();
    timer.start();
    var msg = await ctx.channel.send(content: "Pinging...");
    timer.stop;
    msg.edit(content: ":stopwatch: Pong! `${timer.elapsedMilliseconds}ms`");
  }
}
