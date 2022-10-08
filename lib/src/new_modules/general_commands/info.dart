import 'dart:collection';
import 'dart:io';

import 'package:date_time_format/date_time_format.dart';
import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCDatabase.dart';

class InfoCommand extends TextCommand {
  @override
  String get name => "info";

  @override
  String get description => "Get some information about the bot's status.";

  @override
  HashSet<String> get aliases => HashSet.from(["status"]);

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    CCDatabase db = CCDatabase(initializing: false);

    String memUsage = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
    String uptime = DateTimeFormat.relative(DateTime.now(),
        relativeTo: ctx.client.startTime, levelOfPrecision: 5, abbr: true);

    String prefix;
    if (ctx.guild == null) {
      prefix = ".";
    } else {
      prefix = await db.getPrefix(ctx.guild!.id.id);
    }

    var embed = await EmbedBuilder()
      ..addField(name: "Uptime", content: uptime, inline: true)
      ..addField(name: "Memory Usage", content: "$memUsage MB", inline: true)
      ..addField(name: "Nyxx Version", content: "${ctx.client.version}", inline: true)
      ..addField(name: "(Cached) Guilds", content: ctx.client.guilds.length, inline: true)
      ..addField(name: "(Cached) Users", content: ctx.client.users.length, inline: true)
      ..addField(name: "Prefix", content: prefix, inline: true)
      ..addField(name: "Creator", content: "Nub#8399", inline: true)
      ..addAuthor((author) {
        author.name = ctx.client.self.tag;
        author.iconUrl = ctx.client.self.avatarURL(format: "png");
      })
      ..timestamp = DateTime.now().toUtc()
      ..color = DiscordColor.fromHexString("87CEEB");

    await ctx.channel.sendMessage(MessageBuilder.embed(embed)
      ..allowedMentions = (AllowedMentions()..allow(reply: false))
      ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
  }
}
