import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCDatabase.dart';

class EatCommand extends TextCommand {
  @override
  String get name => "eat";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    var db = CCDatabase(initializing: false);
    int cookieCount = await db.getCookieCount(ctx.author.id.id, ctx.guild!.id.id);

    if (cookieCount >= 1) {
      await db.removeCookies(ctx.author.id.id, 1, ctx.guild!.id.id);
      ctx.channel.sendMessage(MessageBuilder.content("You ate 1 cookie! very tasty :cookie:")
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
        ..allowedMentions = (AllowedMentions()..allow(reply: false)));
    } else {
      ctx.channel.sendMessage(MessageBuilder.content("You ate your favorite imaginary cookie!")
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
        ..allowedMentions = (AllowedMentions()..allow(reply: false)));
    }
  }
}
