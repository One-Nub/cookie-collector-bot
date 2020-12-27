///This file relates to the chat management required for chat collection of cookies.
import 'package:nyxx/nyxx.dart';
import '../main.dart';

import 'dart:collection';

const conversationDelay = Duration(seconds: 90);
const lastSuccessDelay = Duration(minutes: 3);

class ChatListener {
  late Snowflake guildId;
  late Stream<MessageReceivedEvent> guildStream;
  HashSet<Snowflake> ignoreChannels = HashSet();
  
  late LastMessage? lastMessage;
  late DateTime lastSuccessfulTrigger;
  
  ChatListener(this.guildId) {
    guildStream = _guildStreamCreator(guildId);
    lastSuccessfulTrigger = DateTime.now().toUtc();
    lastMessage = null;
    //TODO: Create way to get and load ignored channels (and figure out how to update)
    _lastMessageHandler();
  }

  Stream<MessageReceivedEvent> _guildStreamCreator (Snowflake guildID) {
  return bot.onMessageReceived.where((event) { 
      //Don't add to stream if it's a DM, a bot sending the message, or an ignored channel
    if (event.message is DMMessage || event.message.author.bot || 
      ignoreChannels.contains(event.message.channel.id)) {
        return false;
      }
      GuildMessage gMessage = event.message as GuildMessage;
      return gMessage.guild.id == guildID;
    });
  }

  /// Determines the ability of two messages relative to each other to trigger a cookie collection message
  /// from the bot in the chat.
  void _lastMessageHandler() async {
    await for (MessageReceivedEvent mre in guildStream) {
      LastMessage latestMessage = LastMessage(mre.message as GuildMessage);
      
      //Set lastMessage if last is null, or is the same author.
      if (lastMessage == null || mre.message.author == lastMessage?.lastGuildMessage.author) {
        lastMessage = latestMessage;
        continue;
      }

      //Handles the cooldown of triggers
      DateTime allowedTriggerTime = lastSuccessfulTrigger.add(lastSuccessDelay);
      if (allowedTriggerTime.isAfter(latestMessage.messageTime)) {
        //Don't set the last message here or else it will trigger on first message after the cooldown
        continue;
      }

      //Handles cooldown between messages - when positive (within 90s) will pass over this.
      if (lastMessage!.compareTime(latestMessage) < 0) {
        lastMessage = latestMessage;
        continue;
      }

      
      
      //TODO: Ultimately trigger the sending method & update last trigger.
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

