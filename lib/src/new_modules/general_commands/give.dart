import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCBot.dart';
import '../../core/CCDatabase.dart';
import '../../utilities/parse_id.dart';

class GiveCommand extends TextCommand {
  @override
  String get name => "give";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    if (ctx.guild == null || ctx.author.id.id != 156872400145874944) return;

    //need 2 arguments, user and amount of cookies to give
    if (args.isEmpty || args.length < 2) {
      ctx.channel.sendMessage(MessageBuilder.content("A user and an amount of cookies to give was expected.")
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
        ..allowedMentions = (AllowedMentions()..allow(reply: false)));
      return;
    }

    Iterator argsIterator = args.iterator;
    argsIterator.moveNext();

    int? userID = parseID(argsIterator.current);
    if (userID == null) {
      ctx.channel.sendMessage(MessageBuilder.content("No user ID was found in your message.")
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
        ..allowedMentions = (AllowedMentions()..allow(reply: false)));
      return;
    }

    if (userID == ctx.author.id.id) {
      ctx.channel.sendMessage(
          MessageBuilder.content("You can't give cookies to yourself! That's not how self care works..?")
            ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
            ..allowedMentions = (AllowedMentions()..allow(reply: false)));
    }

    argsIterator.moveNext();
    int? cookieCount = int.tryParse(argsIterator.current);
    if (cookieCount == null) {
      ctx.channel.sendMessage(MessageBuilder.content("An amount of cookies to give was expected.")
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
        ..allowedMentions = (AllowedMentions()..allow(reply: false)));
      return;
    }

    IMember? member = await OnyxConverter.getGuildMember(ctx.client, ctx.guild!.id.id, memberID: userID);
    if (member == null) {
      ctx.channel
          .sendMessage(MessageBuilder.content("A user with the ID of `$userID` was not found in this server.")
            ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
            ..allowedMentions = (AllowedMentions()..allow(reply: false)));
      return;
    }

    CCDatabase db = CCDatabase(initializing: false);
    int userCookieCount = await db.getCookieCount(ctx.author.id.id, ctx.guild!.id.id);
    if (userCookieCount < cookieCount || cookieCount <= 0) {
      ctx.channel.sendMessage(MessageBuilder.content(
          "You can't give `$cookieCount` cookies... Try checking the cookie jar next time!")
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
        ..allowedMentions = (AllowedMentions()..allow(reply: false)));
      return;
    }

    giveCookies(ctx: ctx, member: member, cookieCount: cookieCount);
    await ctx.message.delete();
  }

  Future<void> giveCookies(
      {required TextCommandContext ctx, required IMember member, required int cookieCount}) async {
    CCDatabase db = CCDatabase(initializing: false);

    if (cookieCount >= 50) {
      var bot = CCBot();
      var interactions = bot.interactions;

      ComponentMessageBuilder cmb = ComponentMessageBuilder();
      String memberTag = (await member.user.getOrDownload()).tag;

      cmb.content = "Please confirm that you want to send **$memberTag** `$cookieCount` cookies.";
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
          await buttonEvent.sendFollowup(MessageBuilder.content("Cookie transfer cancelled."), hidden: true);
          return;
        } else if (buttonID == "approve") {
          await confirmMsg.delete();
          await buttonEvent.acknowledge();
        }
      } on TimeoutException {
        await confirmMsg.delete();
      }
    }

    await db.addCookies(member.id.id, cookieCount, ctx.guild!.id.id);
    await db.removeCookies(ctx.author.id.id, cookieCount, ctx.guild!.id.id);

    var finalEmbed = EmbedBuilder()
      ..title = "How generous! :cookie:"
      ..description = "<@${ctx.author.id}> gave ${member.mention} $cookieCount cookies!";
    ctx.channel.sendMessage(
        MessageBuilder.embed(finalEmbed)..allowedMentions = (AllowedMentions()..allow(reply: false)));
  }
}
