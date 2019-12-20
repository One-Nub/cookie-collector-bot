part of commands;

@Command("ping", typing: true)
Future<void> ping(CommandContext ctx) async {
  var stopwatch = Stopwatch();
  stopwatch.start();
  await ctx.waitForTyping(bot.self);
  stopwatch.stop();
  ctx.message.reply(content: ":stopwatch: Pong! `${stopwatch.elapsedMilliseconds}ms`", mention: false);
}
