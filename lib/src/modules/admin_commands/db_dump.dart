import 'dart:async';
import 'dart:convert';

import 'package:cookie_collector_bot/core.dart';
import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

class DumpDatabaseCommand extends TextCommand {
  @override
  String get name => "db_dump";

  @override
  String get description => "Dump the database in JSON format.";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    if (ctx.guild == null) return;

    CCBot bot = CCBot();
    if (!bot.adminList.contains(ctx.author.id)) {
      return;
    }

    CCDatabase db = CCDatabase(initializing: false);
    String query = "SELECT * FROM users_guilds";

    var result = await db.pool.execute(query);
    var iterator = result.rows.iterator;

    Map<String, List> guildMapping = {};

    CCRedis redis = CCRedis();

    while (iterator.moveNext()) {
      var thisRow = iterator.current.typedAssoc();

      String guildId = thisRow["guild_id"].toString();
      String userId = thisRow["user_id"].toString();
      thisRow.remove("guild_id");
      thisRow.remove("partner_id");
      thisRow.remove("lifetime_cookies");

      var data = await redis.getDailyStreakData(int.parse(guildId), int.parse(userId));
      if (data.isNotEmpty) {
        int? sd = int.tryParse(data["streak-duration"] ??= "");
        if (sd != null) {
          thisRow["streak_duration"] = sd;
        }
      }

      if (!guildMapping.containsKey(guildId)) {
        guildMapping[guildId] = [];
      }

      guildMapping[guildId]?.add(thisRow);
    }

    JsonEncoder encoder = JsonEncoder.withIndent("  ");

    List<int> fileOut = utf8.encode(encoder.convert(guildMapping));
    MessageBuilder mb = MessageBuilder.files([AttachmentBuilder.bytes(fileOut, "DB_DUMP.json")]);
    await ctx.channel.sendMessage(mb);
  }
}
