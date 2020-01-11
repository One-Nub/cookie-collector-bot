part of commands;

var _manualCooldown = UserBasedCache();

@Restrict(requiredContext: ContextType.guild)
@Command("daily", aliases: ["loot"])
Future<void> daily(CommandContext ctx) async {
  int dailyCookieCount = 15;
  var nowUtc = DateTime.now().toUtc();

  if (!_manualCooldown.hasKey(ctx.author.id) || 
      nowUtc.difference(_manualCooldown[ctx.author.id]).inDays >= 1) {

    _manualCooldown.add(ctx.author.id, nowUtc);
    db.add_cookies(ctx.author.id.toInt(), dailyCookieCount, ctx.guild.id.toInt());
    ctx.message.reply(content: "You have collected your daily "
      "**$dailyCookieCount** cookies! You can collect again in 24 hours!");
  }
  else {
    var diff = nowUtc.difference(_manualCooldown[ctx.author.id]).inMinutes;
    var hourlyDiff = 24 - (diff / 60);
    ctx.message.reply(content: "It hasn't been a day yet! You can collect "
      "again in ${hourlyDiff.toStringAsFixed(2)} hours");
  }
}
