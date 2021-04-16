part of framework;

const promptTimeout = Duration(seconds: 75);
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
  "nom"
];

class CollectionMessage {

  late GuildChannel channel;
  late int cookieAmount;
  late String triggerMessage;
  late Stream<MessageReceivedEvent> channelStream;

  late Message botMessage;

  CollectionMessage(this.channel, this.channelStream) {
    cookieAmount = 1 + Random().nextInt(7);
    setTrigger();
    sendMessage();
  }

  Future<void> setTrigger() async {
    //TODO: Get prefix from database
    int randNum = Random().nextInt(collectTriggers.length);
    triggerMessage = "." + collectTriggers[randNum];
  }

  Future<void> sendMessage() async {
    String pluaralization = "$cookieAmount cookie${cookieAmount != 1 ? "s" : ""}";
    EmbedBuilder collectionEmbed = EmbedBuilder()
      ..title = triggerMessage
      ..description = "Say that to collect $pluaralization! (Or don't that on you...)"
      ..addFooter((footer) {
        footer.text = "This will expire in ${promptTimeout.inSeconds} seconds!";
      });

    TextGuildChannel tgChannel = channel as TextGuildChannel;

    bool permCheck = await checkPermissions();
    if (!permCheck) {
      return;
    }

    try {
      botMessage = await tgChannel.sendMessage(embed: collectionEmbed);

      var collectionEvent = await channelStream.firstWhere((element) {
        return element.message.content == triggerMessage;
      }).timeout(promptTimeout);

      botMessage.delete();
      collectionEvent.message.delete();

      int authorID = collectionEvent.message.author.id.id;

      AllowedMentions mentions = AllowedMentions()..allow(users: false);
      tgChannel.sendMessage(content: "<@$authorID> "
        "collected $pluaralization!", allowedMentions: mentions)
          .then((msg) {
            Timer(Duration(seconds: 5), () => msg.delete());
          });

      db.addCookies(authorID, cookieAmount, tgChannel.guild.id.id);
      db.addLifetimeCookies(authorID, cookieAmount, tgChannel.guild.id.id);
    }
    on TimeoutException catch(e) {
      //Triggers on timeout from the stream
      botMessage.delete();
    }
  }

  Future<bool> checkPermissions() async {
    //Hoops to get bot user in the guild for permission checking
    Guild channelGuild = await channel.guild.getOrDownload();
    Member botMember = await channelGuild.fetchMember(bot.self.id);

    Permissions botPerms = await channel.effectivePermissions(botMember);
    return (botPerms.administrator ||
      (botPerms.sendMessages && botPerms.manageMessages));
  }
}