import 'dart:async';
import 'dart:math';

import 'package:cookie_collector_bot/core.dart';
import 'package:nyxx/nyxx.dart';

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
    int cookieAmount = 1 + Random().nextInt(10);
    String cookieAmountString = "$cookieAmount cookie${cookieAmount != 1 ? "s" : ""}";

    if (!await _checkPermissions(trigger.channel as IGuildChannel)) return;

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

      trigger.channel
          .sendMessage(MessageBuilder()
            ..content = "<@$authorID> ($authorTag) collected $cookieAmountString!"
            ..allowedMentions = mentions)
          .then((value) => {Timer(Duration(seconds: 5), () => value.delete())});

      CCDatabase database = CCDatabase(initializing: false);
      database.addCookies(authorID, cookieAmount, trigger.guild!.id.id);
      database.addLifetimeCookies(authorID, cookieAmount, trigger.guild!.id.id);
    } on TimeoutException {
      await collectionMsg.delete();
    }
  }

  Future<bool> _checkPermissions(IGuildChannel channel) async {
    //Hoops to get bot user in the guild for permission checking
    IGuild channelGuild = await channel.guild.getOrDownload();
    IMember botMember = await channelGuild.fetchMember(channel.client.appId);

    IPermissions botPerms = await channel.effectivePermissions(botMember);
    return (botPerms.administrator || (botPerms.sendMessages && botPerms.manageMessages));
  }
}
