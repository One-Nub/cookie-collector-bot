part of commands;

class Ping {
  static Future<bool> preRunChecks(CommandContext ctx) async {
    if(ctx.guild == null) return false;

    Member botMember = ctx.guild!.selfMember!;
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
    var msg = await ctx.channel.sendMessage(content: "Pinging...");
    timer.stop;
    msg.edit(content: ":stopwatch: Pong! `${timer.elapsedMilliseconds}ms`");
  }
}
