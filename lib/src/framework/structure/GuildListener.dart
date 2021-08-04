part of framework;

class GuildListener {
  late Guild guild;
  late Snowflake guildID;
  late Stream<MessageReceivedEvent> guildStream;

  HashSet<Snowflake> ignoredChannels = HashSet();
  HashMap<Snowflake, ChannelListener> listenedChannels = HashMap();

  GuildListener(this.guild) {
    guildID = guild.id;
    guildStream = _guildStreamCreator(guildID);
    _initalize();
  }

  Stream<MessageReceivedEvent> _guildStreamCreator (Snowflake guildID) {
  return bot.onMessageReceived.where((event) {
    //Don't add to stream if it's a DM, a bot sending the message, or an ignored channel
    if (event.message is DMMessage || event.message.author.bot ||
      ignoredChannels.contains(event.message.channel.id)) {
        return false;
      }
      GuildMessage gMessage = event.message as GuildMessage;
      return gMessage.guild.id == guildID;
    });
  }

  void _initalize() async {
    //TODO: Fetch and populate ignored channels (ignoredChannels list)
    guild.channels.forEach((channel) {
      if(!ignoredChannels.contains(channel.id)) {
        ChannelListener chnl = ChannelListener(channel, _guildStreamCreator(guildID));
        listenedChannels.putIfAbsent(channel.id, () => chnl);
      }
    });
  }

  void ignoreChannel(Snowflake channelID) {
    //TODO: Update database
    ignoredChannels.add(channelID);
    if(listenedChannels.containsKey(channelID)) {
      //Set the method to be ignored
      listenedChannels[channelID]!.ignoreChannel = true;
      //Remove the reference - the listener should then be garbage collected by dart
      listenedChannels.remove(channelID);
      return;
    }
  }

  Future<bool> unignoreChannel(Snowflake channelID) async {
    //Remove channel ID from ignoredChannels list if exists
    //TODO: Update database
    if(ignoredChannels.contains(channelID)) {
      ignoredChannels.remove(channelID);
    }

    if(listenedChannels.containsKey(channelID)) {
      listenedChannels[channelID]!.ignoreChannel = false;
      return true;
    }
    else {
      var guildChannel = await bot.fetchChannel(channelID) as GuildChannel;
      ChannelListener channelListener = ChannelListener(guildChannel, guildStream);
      listenedChannels.putIfAbsent(channelID, () => channelListener);
      return true;
    }
  }
}