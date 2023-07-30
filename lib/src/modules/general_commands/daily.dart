import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCDatabase.dart';
import '../../core/CCRedis.dart';

const Duration cooldown = Duration(days: 1);

const int baseReward = 15;
const int rewardIncInterval = 5;

class DailyCommand extends TextCommand {
  String get name => "daily";

  @override
  String get description => "Collect your daily cookies!";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    int authorID = ctx.author.id.id;

    if (ctx.guild == null) {
      await ctx.channel.sendMessage(MessageBuilder.content("You can't use this command in DMs!")
        ..allowedMentions = (AllowedMentions()..allow(reply: false))
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
      return;
    }

    int guildID = ctx.guild!.id.id;

    CCRedis redis = CCRedis();
    Map<String, dynamic> streakData = await redis.getDailyStreakData(guildID, authorID);

    if (streakData.isEmpty) {
      int streakDuration = await redis.increaseDailyStreak(guildID, authorID, DateTime.now().toUtc());
      await collectCookies(ctx, streakDuration);
      return;
    }

    int lucMs = int.parse(streakData["lastUserCollection"]);
    DateTime lastCollectTime = DateTime.fromMillisecondsSinceEpoch(lucMs, isUtc: true);
    DateTime cooldownTime = lastCollectTime.add(cooldown);

    if (cooldownTime.isAfter(DateTime.now().toUtc())) {
      EmbedBuilder errorEmbed = EmbedBuilder()
        ..color = DiscordColor.fromHexString("6B0504")
        ..description = "It hasn't been a full day yet! You can collect your daily cookies "
            "<t:${(cooldownTime.millisecondsSinceEpoch / 1000).round()}:R>."
        ..addAuthor((author) {
          author.name = ctx.author.tag;
          author.iconUrl = ctx.author.avatarURL(format: "png");
        });
      await ctx.channel.sendMessage(MessageBuilder.embed(errorEmbed)
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
        ..allowedMentions = (AllowedMentions()..allow(reply: false)));
      return;
    }

    /// No checking for overtime since if the key expired, the streak will start at 1 again.
    int streakLength = await redis.increaseDailyStreak(guildID, authorID, DateTime.now().toUtc());
    await collectCookies(ctx, streakLength);
  }

  Future<void> collectCookies(TextCommandContext ctx, int streakLength) async {
    int streakRewardModifier = ((streakLength / 8) - sin(streakLength / 6 * 2)).ceil();

    int reward = baseReward + streakRewardModifier;
    CCDatabase db = CCDatabase(initializing: false);
    await db.addCookies(ctx.author.id.id, reward, ctx.guild!.id.id);
    await db.addLifetimeCookies(ctx.author.id.id, reward, ctx.guild!.id.id);

    EmbedBuilder replyEmbed = EmbedBuilder()
      ..description = "You have collected your daily `$reward` cookies! \n"
          "You are now on a streak of `$streakLength` day${(streakLength != 1) ? "s" : ""}."
      ..timestamp = DateTime.now().toUtc().add(Duration(days: 1))
      ..color = DiscordColor.fromHexString("67F399");
    replyEmbed.addAuthor((author) {
      author.name = "Daily Cookies - ${ctx.author.tag}";
      author.iconUrl = ctx.author.avatarURL(format: "png");
    });
    replyEmbed.addFooter((footer) {
      footer.text = "You can collect again in 24 hours.";
    });

    await ctx.channel.sendMessage(MessageBuilder.embed(replyEmbed)
      ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
      ..allowedMentions = (AllowedMentions()..allow(reply: false)));
  }
}
