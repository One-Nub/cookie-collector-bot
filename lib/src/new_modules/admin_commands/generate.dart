import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../utilities/parse_id.dart';

class GenerateCommand extends TextCommand {
  @override
  String get name => "generate";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    if (ctx.guild == null || ctx.author.id.id != 156872400145874944) return;

    //need 2 arguments, user and amount of cookies to give
    if (args.isEmpty || args.length < 2) {
      ctx.channel
          .sendMessage(MessageBuilder()..content = "A user and an amount of cookies to give was expected.");
      return;
    }

    Iterator argsIterator = args.iterator;
    argsIterator.moveNext();

    int? userID = parseID(argsIterator.current);
    if (userID == null) {
      ctx.channel.sendMessage(MessageBuilder()..content = "No matching user ID was found.");
      return;
    }

    argsIterator.moveNext();
    int? cookieCount = int.tryParse(argsIterator.current);
    if (cookieCount == null) {
      ctx.channel.sendMessage(MessageBuilder()..content = "An amount of cookies to give was expected.");
    }

    OnyxConverter.getGuildMember(ctx.client, ctx.guild!.id.id, memberID: userID);
    ctx.channel.sendMessage(MessageBuilder()..content = "No.");
  }

  Future<void> giveCookies({required int userID, required int cookieCount}) async {}
}
