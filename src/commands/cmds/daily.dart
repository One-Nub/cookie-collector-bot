// part of commands;

// var _manualCooldown = UserBasedCache();

// @Restrict(requiredContext: ContextType.guild)
// @Command("daily", aliases: ["loot"])
// Future<void> daily(CommandContext ctx) async {
//   int dailyCookieCount = 15;
//   var nowUtc = DateTime.now().toUtc();

//   if(_manualCooldown.hasKey(ctx.author.id) &&
//       _manualCooldown[ctx.author.id].isAfter(nowUtc)) {
//     var diff = _manualCooldown[ctx.author.id].difference(nowUtc).toString();
//     var timeSplit = diff.split(":");
//     var remainingTime = "`${timeSplit[0]} hours, ${timeSplit[1]} minutes, "
//     "and ${timeSplit[2].substring(0, 2)} seconds`";

//     ctx.message.reply(content: "It hasn't been a day yet! You can collect "
//       "again in $remainingTime.");
//   }
//   else {
//     _manualCooldown.add(ctx.author.id, nowUtc.add(new Duration(days: 1)));
//     await db.add_cookies(ctx.author.id.toInt(), dailyCookieCount, ctx.guild.id.toInt());
//     await ctx.message.reply(content: "You have collected your daily "
//       "`$dailyCookieCount` cookies! You can collect again in 24 hours!");
//   }
// }
