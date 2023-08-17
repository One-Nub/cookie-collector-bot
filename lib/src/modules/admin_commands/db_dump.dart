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
    if (ctx.guild == null || ctx.author.id.id != 156872400145874944) return;

    CCDatabase db = CCDatabase(initializing: false);
    String query = "SELECT * FROM users_guilds";

    var result = await db.pool.execute(query);
    var iterator = result.rows.iterator;

    Map<String, List> guildMapping = {};

    while (iterator.moveNext()) {
      var thisRow = iterator.current.typedAssoc();
      print(thisRow);

      String guildId = thisRow["guild_id"].toString();
      thisRow.remove("guild_id");
      thisRow.remove("partner_id");

      if (!guildMapping.containsKey(guildId)) {
        guildMapping[guildId] = [];
      }

      guildMapping[guildId]?.add(thisRow);
    }

    List<int> fileOut = utf8.encode(jsonEncode(guildMapping).toString());
    MessageBuilder mb = MessageBuilder.files([AttachmentBuilder.bytes(fileOut, "DB_DUMP.json")]);
    await ctx.channel.sendMessage(mb);
  }
}
