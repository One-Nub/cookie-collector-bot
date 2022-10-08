import 'dart:collection';

import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCBot.dart';
import '../../core/CCDatabase.dart';
import '../../utilities/parse_id.dart';

class StatsCommands extends TextCommand {
  @override
  String get name => "stats";

  @override
  String get description => "View how many cookies someone, or yourself, has!";

  @override
  HashSet<String> get aliases => HashSet.from(["bal", "balance"]);

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    int? userID;
    if (args.isNotEmpty) {
      userID = parseID(args.first);
    }
    userID ??= ctx.author.id.id;

    CCDatabase db = CCDatabase(initializing: false);
    var databaseResult = await db.getRankedUserGuildData(userID, ctx.guild!.id.id);
    Map<String, dynamic> userMap = {"user_id": userID, "cookies": 0, "row_num": "N/A"};
    if (databaseResult != null && databaseResult.rows.isNotEmpty) {
      userMap = databaseResult.rows.first.typedAssoc();
    }

    CCBot bot = CCBot();
    IUser user = await bot.gateway.fetchUser(Snowflake(userID));

    EmbedBuilder statsEmbed = EmbedBuilder()
      ..addField(name: "**Cookies**", content: userMap["cookies"], inline: true)
      ..addField(name: "**Rank**", content: userMap["row_num"], inline: true)
      ..color = DiscordColor.fromHexString("87CEEB")
      ..description = (databaseResult!.rows.isEmpty)
          ? "**This user does not have any data stored in the database for this server!**"
          : ""
      ..thumbnailUrl = user.avatarURL(format: "png", size: 512)
      ..timestamp = DateTime.now().toUtc()
      ..title = "${user.tag}'s Stats";

    await ctx.channel.sendMessage(MessageBuilder.embed(statsEmbed)
      ..allowedMentions = (AllowedMentions()..allow(reply: false))
      ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
  }
}
