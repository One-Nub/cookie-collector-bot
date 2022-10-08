import 'package:nyxx/nyxx.dart';

import 'collect_msg.dart';

const conversationDelay = Duration(seconds: 90);
const lastSuccessDelay = Duration(minutes: 3);

Map<Snowflake, IMessage> lastMessageMap = Map();
Map<Snowflake, DateTime> lastTriggerMap = Map();

void onMessageEvent(IMessageReceivedEvent event) async {
  if (event.message.author.bot) return;
  //would ignore channel here if that was actually implemented

  // print("message recieved");
  // print(lastMessageMap);
  // print(lastTriggerMap);

  Snowflake channelID = event.message.channel.id;
  IMessage? lastMessage = lastMessageMap[channelID];
  IMessage newMessage = event.message;
  DateTime? lastTriggerTime = lastTriggerMap[channelID];

  if (lastTriggerTime == null) {
    // set last trigger time in case it's not a thing
    lastTriggerMap[channelID] = DateTime.now();
    return;
  }

  /// Set last message if the last one is null, or if it's the same author
  if (lastMessage == null || newMessage.author.id == lastMessage.author.id) {
    lastMessageMap[channelID] = newMessage;
    return;
  }

  DateTime nextAllowedTrigger = lastTriggerTime.add(lastSuccessDelay);
  if (nextAllowedTrigger.isAfter(newMessage.createdAt)) return;

  /// Don't send the collection message if it's been over [conversationDelay] time length.
  DateTime messageWithConvoDelay = lastMessage.createdAt.add(conversationDelay);
  if (newMessage.createdAt.isAfter(messageWithConvoDelay)) {
    lastMessageMap[channelID] = newMessage;
    return;
  }

  CollectionMessage collectionMessage = CollectionMessage();
  collectionMessage.generateTrigger();
  collectionMessage.handleTriggerCollection(newMessage);

  lastMessageMap[channelID] = newMessage;
  lastTriggerMap[channelID] = newMessage.createdAt;
}
