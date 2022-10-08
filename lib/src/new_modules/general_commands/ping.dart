import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

class PingCommand extends TextCommand {
  @override
  String get name => "ping";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    Stopwatch timer = Stopwatch();
    timer.start();
    var message = await ctx.channel.sendMessage(MessageBuilder.content("Pinging...")
      ..allowedMentions = (AllowedMentions()..allow(reply: false))
      ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
    timer.stop();
    await message.edit(MessageBuilder.content(":stopwatch: Pong! `${timer.elapsedMilliseconds}ms`"));
  }
}
