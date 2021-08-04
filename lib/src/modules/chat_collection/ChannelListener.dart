import 'package:nyxx/nyxx.dart';

import 'CollectionMessage.dart';
import '../../core/CCBot.dart';

const conversationDelay = Duration(seconds: 90);
const lastSuccessDelay = Duration(minutes: 3);

class ChannelListener {
  late bool ignoreChannel;

  late CCBot bot;
  late GuildChannel channel;
  late Snowflake channelID;
  late Stream<MessageReceivedEvent> guildStream;
  late Stream<MessageReceivedEvent> channelStream;

  late LastMessage? lastMessage;
  late DateTime lastTrigger;

  ChannelListener(this.bot, this.channel, this.guildStream, {this.ignoreChannel = false}) {
    channelID = channel.id;
    lastMessage = null;
    lastTrigger = DateTime.now().toUtc().subtract(Duration(minutes: 5));
    channelStream = _initializeChannelStream();

    _messageHandler();
  }

  Stream<MessageReceivedEvent> _initializeChannelStream() {
    return guildStream.where((event) {
      return event.message.channel.id == channelID;
    });
  }

  /// Determines the ability of two messages relative to each other to trigger a cookie collection message
  /// from the bot in the chat.
  void _messageHandler() async {
    await for (MessageReceivedEvent mre in channelStream) {
      LastMessage latestMessage = LastMessage(mre.message as GuildMessage);

      if (ignoreChannel) continue;

      //Set lastMessage if last is null, or is the same author.
      if (lastMessage == null || mre.message.author.id == lastMessage?.authorId) {
        lastMessage = latestMessage;
        continue;
      }

      //Handles the cooldown of triggers
      DateTime allowedTriggerTime = lastTrigger.add(lastSuccessDelay);
      if (allowedTriggerTime.isAfter(latestMessage.messageTime)) {
        //Don't set the last message here or else it will trigger on first message after the cooldown
        continue;
      }

      //Handles cooldown between messages - when positive (within conversationDelay) will pass over this.
      if (lastMessage!.compareTime(latestMessage) < 0) {
        lastMessage = latestMessage;
        continue;
      }

      CollectionMessage(bot, bot.database, channel, channelStream);
      lastMessage = latestMessage;
      lastTrigger = DateTime.now().toUtc();
    }
  }
}

class LastMessage {
  //The message object
  late GuildMessage lastGuildMessage;
  //The time the last message was sent
  late DateTime messageTime;
  //The maximum time that will allow for a successful trigger of the collection message.
  late DateTime nextSuccessThreshold;
  //Previous message author
  late Snowflake authorId;

  LastMessage(this.lastGuildMessage) {
    messageTime = lastGuildMessage.createdAt;
    nextSuccessThreshold = messageTime.add(conversationDelay);
    authorId = lastGuildMessage.author.id;
  }

  /// Determines if the current LastMessage is within the time threshold relative to the parameter message.
  /// Returns:
  ///   Negative if outside the time threshold.
  ///   Zero if time is matching.
  ///   Positive if inside the time threshold.
  int compareTime(LastMessage message) {
    return nextSuccessThreshold.compareTo(message.messageTime);
  }
}