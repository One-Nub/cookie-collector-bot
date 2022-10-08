import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCDatabase.dart';

final Map<String, DateTime> lastUserCollection = Map();
final Map<String, int> userStreak = Map();
const Duration latestDelay = Duration(days: 2);
const Duration cooldown = Duration(days: 1);

const int baseReward = 15;
const int rewardIncInterval = 5;

class DailyCommand extends TextCommand {
  String get name => "daily";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    int authorID = ctx.author.id.id;
    int guildID = ctx.guild!.id.id;

    /// workaround to not have to deal with nested maps like in the prior code.
    String mapEntry = "$guildID-$authorID";

    if (!lastUserCollection.containsKey(mapEntry)) {
      userStreak[mapEntry] = 1;
      lastUserCollection[mapEntry] = DateTime.now();
      await collectCookies(ctx, mapEntry);
      return;
    }

    DateTime lastCollectTime = lastUserCollection[mapEntry]!;
    DateTime cooldownTime = lastCollectTime.add(cooldown);
    if (cooldownTime.isAfter(DateTime.now())) {
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

    DateTime latestDelayTime = lastCollectTime.add(latestDelay);
    int userStreakDays = userStreak[mapEntry]!;
    if (latestDelayTime.isAfter(DateTime.now())) {
      userStreak[mapEntry] = 1;
    } else {
      userStreak[mapEntry] = userStreakDays + 1;
    }

    lastUserCollection[mapEntry] = DateTime.now();
    await collectCookies(ctx, mapEntry);
  }

  Future<void> collectCookies(TextCommandContext ctx, String mapEntry) async {
    int streakLength = userStreak[mapEntry]!;

    int streakRewardModifier = (streakLength < 30)
        ? (streakLength / rewardIncInterval).floor() * 2
        : (30 / rewardIncInterval).floor() * 2;

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
