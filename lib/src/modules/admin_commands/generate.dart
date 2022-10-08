import 'dart:async';

import 'package:cookie_collector_bot/core.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../utilities/parse_id.dart';

class GenerateCommand extends TextCommand {
  @override
  String get name => "generate";

  @override
  String get description => "Generate some cookies for someone.";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    if (ctx.guild == null || ctx.author.id.id != 156872400145874944) return;

    //need 2 arguments, user and amount of cookies to give
    if (args.isEmpty || args.length < 2) {
      ctx.channel
          .sendMessage(MessageBuilder.content("A user and an amount of cookies to give was expected."));
      return;
    }

    Iterator argsIterator = args.iterator;
    argsIterator.moveNext();

    int? userID = parseID(argsIterator.current);
    if (userID == null) {
      ctx.channel.sendMessage(MessageBuilder.content("No user ID was found in your message."));
      return;
    }

    argsIterator.moveNext();
    int? cookieCount = int.tryParse(argsIterator.current);
    if (cookieCount == null) {
      ctx.channel.sendMessage(MessageBuilder.content("An amount of cookies to give was expected."));
      return;
    }

    IMember? member = await OnyxConverter.getGuildMember(ctx.client, ctx.guild!.id.id, memberID: userID);
    if (member == null) {
      ctx.channel.sendMessage(
          MessageBuilder.content("A user with the ID of `$userID` was not found in this server."));
      return;
    }

    giveCookies(ctx: ctx, member: member, cookieCount: cookieCount);
    await ctx.message.delete();
  }

  Future<void> giveCookies(
      {required TextCommandContext ctx, required IMember member, required int cookieCount}) async {
    var bot = CCBot();
    var interactions = bot.interactions;

    ComponentMessageBuilder cmb = ComponentMessageBuilder();
    String memberTag = (await member.user.getOrDownload()).tag;
    cmb.content = "Please verify your intentions: `$memberTag` "
        "will receive $cookieCount cookies";
    cmb.componentRows = [
      ComponentRowBuilder()
        ..addComponent(ButtonBuilder("Deny", "deny", ButtonStyle.danger))
        ..addComponent(ButtonBuilder("Approve", "approve", ButtonStyle.success))
    ];

    var confirmMsg = await ctx.channel.sendMessage(cmb);
    try {
      var buttonEvent = await interactions.events.onButtonEvent.firstWhere((element) {
        return element.interaction.userAuthor!.id == ctx.message.author.id &&
            (element.interaction.customId == "deny" || element.interaction.customId == "approve");
      }).timeout(Duration(seconds: 15));

      String buttonID = buttonEvent.interaction.customId;
      if (buttonID == "deny") {
        await confirmMsg.delete();

        // ack then followup because for some reason just responding edits the original msg instead.
        await buttonEvent.acknowledge();
        await buttonEvent.sendFollowup(
            MessageBuilder.content("Cancelled - `$memberTag`'s cookies have not been modified."),
            hidden: true);
      } else if (buttonID == "approve") {
        var database = CCDatabase(initializing: false);
        await database.addCookies(member.id.id, cookieCount, ctx.guild!.id.id);

        await confirmMsg.delete();

        await buttonEvent.acknowledge();
        await buttonEvent.sendFollowup(
            MessageBuilder.content("Done - `$memberTag` has received `$cookieCount` cookies."),
            hidden: true);
      }
    } on TimeoutException {
      await confirmMsg.delete();
    }
  }
}
