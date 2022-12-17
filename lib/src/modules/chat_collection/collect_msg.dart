import 'dart:async';
import 'dart:math';

import 'package:cookie_collector_bot/core.dart';
import 'package:nyxx/nyxx.dart';

import '../../utilities/event_tiers.dart';

const _promptTimeout = Duration(seconds: 75);
const List<String> collectTriggers = [
  "collect",
  "grab",
  "mine",
  "nab",
  "pick",
  "snatch",
  "yoink",
  "yum",
  "givemecookie",
  "lolyouhadtotypeallthis",
  "john",
  "steal",
  "supercalifragilisticexpialidocious",
  "kidnap",
  "nom",
  "tasty",
  "gingerbread",
  "snickerdoodle",
  "oatmeal raisin",
  "chocolate chip",
  "gingersnap",
  "shortbread",
  "peanut butter",
  "sugar",
  "biscotti",
  "macaroon",
  "macrons",
  "macadamia"
];

class CollectionMessage {
  late String triggerMessage;

  void generateTrigger() {
    int randNum = Random().nextInt(collectTriggers.length);
    triggerMessage = "." + collectTriggers[randNum];
  }

  void handleTriggerCollection(IMessage trigger) async {
    int cookieAmount = 5 + Random().nextInt(5);
    String cookieAmountString = "$cookieAmount cookie${cookieAmount != 1 ? "s" : ""}";
    var channel = await trigger.channel.getOrDownload();
    var botMember = await (await trigger.guild!.getOrDownload()).selfMember.getOrDownload();

    if (!await _checkPermissions(channel as ITextGuildChannel, member: botMember)) return;

    EmbedBuilder messageEmbed = EmbedBuilder()
      ..title = triggerMessage
      ..description = "Say **$triggerMessage** to collect $cookieAmountString! (Or don't that on you...)"
      ..addFooter((footer) {
        footer.text = "This will expire in ${_promptTimeout.inSeconds} seconds!";
      });

    var collectionMsg = await trigger.channel.sendMessage(MessageBuilder.embed(messageEmbed));

    INyxxWebsocket client = trigger.client as INyxxWebsocket;
    try {
      var collectionEvent = await client.eventsWs.onMessageReceived
          .firstWhere((element) => element.message.content == triggerMessage)
          .timeout(_promptTimeout);

      await collectionMsg.delete();
      await collectionEvent.message.delete();

      int authorID = collectionEvent.message.author.id.id;
      String authorTag = collectionEvent.message.author.tag;
      AllowedMentions mentions = AllowedMentions()..allow(users: false);

      int guildID = collectionEvent.message.guild!.id.id;
      int channelID = collectionEvent.message.channel.id.id;
      CCRedis redis = CCRedis();
      var streakData = await redis.getChannelStreakData(channelID);

      int userTier = await getUserTier(guildID, authorID);
      int userBonus = await _getTierBaseBonus(guildID, authorID, userTier: userTier);

      if (streakData.isEmpty || userTier == 0) {
        redis.startChannelStreak(channelID, authorID, baseAmount: userBonus);
      } else {
        int? streakUserID = int.tryParse(streakData["userID"]);
        if (streakUserID == authorID) {
          userBonus = await redis.increaseChannelStreak(channelID);
        } else {
          redis.startChannelStreak(channelID, authorID, baseAmount: userBonus);
        }
      }

      int totalCookies = cookieAmount + userBonus;
      String description = "<@$authorID> ($authorTag) collected $cookieAmountString";
      description += (userBonus == 0)
          ? "!"
          : ", with a streak bonus of $userBonus cookie${userBonus != 1 ? "s" : ""}, "
              "resulting in a total of $totalCookies cookies!";

      trigger.channel
          .sendMessage(MessageBuilder()
            ..content = description
            ..allowedMentions = mentions)
          .then((value) => {Timer(Duration(seconds: 5), () => value.delete())});

      CCDatabase database = CCDatabase(initializing: false);
      database.addCookies(authorID, totalCookies, trigger.guild!.id.id);
      database.addLifetimeCookies(authorID, totalCookies, trigger.guild!.id.id);
    } on TimeoutException {
      await collectionMsg.delete();
    }
  }

  Future<bool> _checkPermissions(ITextGuildChannel channel, {IMember? member}) async {
    //Hoops to get bot user in the guild for permission checking
    IMember botMember;
    if (member != null) {
      botMember = member;
    } else {
      IGuild channelGuild = await channel.guild.getOrDownload();
      botMember = await channelGuild.fetchMember(channel.client.appId);
    }

    IPermissions botPerms = await channel.effectivePermissions(botMember);
    return (botPerms.administrator || (botPerms.sendMessages && botPerms.manageMessages));
  }
}

Future<int> _getTierBaseBonus(int guildID, int userID, {int? userTier}) async {
  int tierResult = (userTier == null) ? await getUserTier(guildID, userID) : userTier;

  /// For the time being this switch case is rather dumb, but I am leaving it
  /// for an instance where the base bonus may wish to be changed per tier.
  switch (tierResult) {
    case 1:
      return 1;
    case 2:
      return 2;
    case 3:
      return 3;
    default:
      return 0;
  }
}
