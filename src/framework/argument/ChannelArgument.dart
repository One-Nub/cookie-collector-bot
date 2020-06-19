part of framework;

/// Facilitates the ability of getting a Channel from a passed input.
///
/// Accepted types: CachelessTextChannel, CacheVoiceChannel, CategoryChannel
/// Throws [GuildContextRequiredException] when run from a non-guild context.
/// Throws [MissingArgumentException] if an argument cannot be found.
/// Throws [InvalidChannelException] if a valid channel cannot be found.
class ChannelArgument<T extends Channel> extends Argument {
  late bool searchChannelNames;

  ChannelArgument(
      {bool pipeDelimiter = false,
      this.searchChannelNames = false,
      bool isRequired = false})
      : super(pipeDelimiter, isRequired);

  @override
  Future<T> parseArg(CommandContext ctx, String message) async {
    if (ctx.guild == null) {
      throw GuildContextRequiredException();
    }
    if(message == "") {
      throw MissingArgumentException();
    }
    
    message = message.trim();
    int channelID = 0;

    //Parse content if the message should have a pipe delimiter
    if (pipeDelimiterExpected && message.contains("|")) {
      message = message.split("|").first.trim();
    } else {
      //Text channels can't have spaces while categories & voice channels can.
      if (T == CachelessTextChannel)
        message = message.split(RegExp("\\s+")).first.trim();
    }

    //Actions to set id.
    if (!_rawIDRegex.hasMatch(message) && searchChannelNames) {
      List<Channel> guildChannels = ctx.guild!.channels.values.toList();

      //O(n) for every channel of T
      for (var channel in guildChannels) {
        if (channel.type == ChannelType.text && T == CachelessTextChannel) {
          channel = channel as CachelessTextChannel;
          if (channel.name.toLowerCase() == message.toLowerCase()) {
            channelID = channel.id.id;
            break;
          }
        } else if (channel.type == ChannelType.voice && T == CacheVoiceChannel) {
          channel = channel as CacheVoiceChannel;
          if (channel.name.toLowerCase() == message.toLowerCase()) {
            channelID = channel.id.id;
            break;
          }
        } else if (channel.type == ChannelType.category && T == CategoryChannel) {
          channel = channel as CategoryChannel;
          if (channel.name.toLowerCase() == message.toLowerCase()) {
            channelID = channel.id.id;
            break;
          }
        }
      }
    } else {
      channelID = _parseIDHelper(message) ?? 0;
    }

    //ID wasn't updated/couldn't be found, or guild does not have a matching channel id.
    if (channelID == 0 || !ctx.guild!.channels.hasKey(Snowflake(channelID))) {
      throw InvalidChannelException("A matching channel could not be found within the guild.");
    }

    try {
      return await ctx.client.getChannel(Snowflake(channelID)) as T;
    } catch (exception) {
      //Safeguard in the sencario that the bot can't get the channel or the type
      //casting doesn't work somehow. I haven't been able to cause this to trigger.
      Logger.root.severe("Type casting issue?: $exception\n");
      throw InvalidChannelException("A major issue was encountered while getting" +
      " the channel in the guild. The error has been logged and will be looked into.");
    }
  }
}