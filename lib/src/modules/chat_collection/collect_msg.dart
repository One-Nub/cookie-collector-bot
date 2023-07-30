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

// question:answer
const Map<String, String> quizTriggers = {
  "What is the other identity of Tony Stark?": "Iron man",
  "What's the secret identity of Spider-man?": "Peter Parker",
};

class CollectionMessage {
  String? triggerQuestion;
  late String triggerMessage;

  void generateTrigger() {
    Random rand = Random.secure();
    // bool choice = rand.nextBool();

    // Choose random trigger when true, quiz when false.
    // if (choice) {
    //   int randNum = rand.nextInt(collectTriggers.length);
    //   triggerMessage = "." + collectTriggers[randNum];
    // } else {
    //   int randNum = rand.nextInt(quizTriggers.length);
    //   triggerQuestion = quizTriggers.keys.elementAt(randNum);
    //   triggerMessage = quizTriggers.values.elementAt(randNum);
    // }

    int randNum = rand.nextInt(collectTriggers.length);
    triggerMessage = "." + collectTriggers[randNum];
  }

  void handleTriggerCollection(IMessage trigger) async {
    int cookieAmount = 5 + Random().nextInt(5);
    String cookieAmountString = "$cookieAmount cookie${cookieAmount != 1 ? "s" : ""}";
    var channel = await trigger.channel.getOrDownload();
    var botMember = await (await trigger.guild!.getOrDownload()).selfMember.getOrDownload();

    // Another safeguard to ignore threads.
    if (channel.runtimeType != ITextGuildChannel) return;

    if (!await _checkPermissions(channel as ITextGuildChannel, member: botMember)) return;
    EmbedBuilder messageEmbed = EmbedBuilder()
      ..title = "Some cookies fell in chat! Grab them!"
      ..description = "> *Repeat the text or answer my question in chat*"
      ..addFooter((footer) {
        footer.text = "Be quick, the cookies will go stale in ${_promptTimeout.inSeconds} seconds!";
      })
      ..color = DiscordColor.fromHexString("20262c");

    if (triggerQuestion != null) {
      messageEmbed.addField(
          name: ":face_with_monocle: Answer my question:", content: triggerQuestion, inline: true);
    } else {
      messageEmbed.addField(name: ":keyboard: Repeat after me!", content: triggerMessage, inline: true);
    }

    messageEmbed.addField(name: ":cookie: Your earnings:", content: "$cookieAmountString", inline: true);

    var collectionMsg = await trigger.channel.sendMessage(MessageBuilder.embed(messageEmbed));

    INyxxWebsocket client = trigger.client as INyxxWebsocket;
    try {
      var collectionEvent = await client.eventsWs.onMessageReceived
          .firstWhere(
              (element) => element.message.content.toLowerCase().trim() == triggerMessage.toLowerCase())
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

      int userTier = await getUserTier(authorID, guildID: guildID);
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
  int tierResult = (userTier == null) ? await getUserTier(userID, guildID: guildID) : userTier;

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
