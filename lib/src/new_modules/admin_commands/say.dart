import 'package:cookie_collector_bot/src/utilities/parse_id.dart';
import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCBot.dart';

class SayCommand extends TextCommand {
  @override
  String get name => "say";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    CCBot bot = CCBot();
    if (!bot.adminList.contains(ctx.author.id)) {
      return;
    }

    if (args.isEmpty) {
      ctx.channel.sendMessage(MessageBuilder.content("I need something to send..."));
      return;
    }

    // remove command name
    message = message.replaceFirst(this.name, '')..trim();

    int? channelID = parseID(args.first);
    if (channelID == null) {
      channelID = ctx.channel.id.id;
    } else {
      // remove channel ID text
      message =
          message.substring(message.contains(">") ? message.indexOf(">") + 1 : message.indexOf(" ")).trim();
      message = message.replaceAll("$channelID", "").trim();
    }

    if (message.isEmpty) {
      ctx.channel.sendMessage(MessageBuilder.content("I need something to send..."));
      return;
    }

    if (channelID == ctx.channel.id.id) {
      ctx.channel.sendMessage(MessageBuilder.content(message)
        ..allowedMentions = (AllowedMentions()..allow(reply: false, everyone: false)));
    } else {
      var channel = await bot.gateway.fetchChannel(Snowflake(channelID));
      try {
        ITextGuildChannel textChannel = channel as ITextGuildChannel;

        var botPerms = await textChannel.effectivePermissions(await ctx.guild!.selfMember.getOrDownload());
        if (botPerms.sendMessages && botPerms.viewChannel) {
          textChannel.sendMessage(MessageBuilder.content(message)
            ..allowedMentions = (AllowedMentions()..allow(reply: false, everyone: false)));
        } else {
          ctx.channel.sendMessage(MessageBuilder.content(
              "I can't send messages in that channel! <a:confuse:724785215838617770>"));
          return;
        }
      } on TypeError {
        ctx.channel.sendMessage(MessageBuilder.content(
            "That doesn't appear to be a valid channel I can send to! <a:confuse:724785215838617770>"));
      }
    }

    await ctx.message.delete();
  }
}
