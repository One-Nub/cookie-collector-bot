import 'package:nyxx/nyxx.dart';
import 'package:logging/logging.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../new_modules/chat_collection/on_message.dart' as cc;

import '../new_modules/admin_commands/generate.dart';
import '../new_modules/admin_commands/say.dart';

import '../new_modules/general_commands/daily.dart';
import '../new_modules/general_commands/eat.dart';
import '../new_modules/general_commands/give.dart';
import '../new_modules/general_commands/help.dart';
import '../new_modules/general_commands/info.dart';
import '../new_modules/general_commands/leaderboard.dart';
import '../new_modules/general_commands/ping.dart';
import '../new_modules/general_commands/rob.dart';
import '../new_modules/general_commands/stats.dart';

class CCBot {
  final String token;
  late final INyxxWebsocket gateway;
  late final OnyxChat onyxChat;

  CCBot({required this.token});

  void startGateway() async {
    CacheOptions cacheOptions = CacheOptions()
      ..memberCachePolicyLocation = CachePolicyLocation.all()
      ..userCachePolicyLocation = CachePolicyLocation.all();

    gateway = NyxxFactory.createNyxxWebsocket(
        token, GatewayIntents.messageContent | GatewayIntents.guildMessages,
        cacheOptions: cacheOptions)
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions())
      ..connect();

    gateway.eventsWs.onReady.listen((event) {
      gateway.setPresence(PresenceBuilder.of(
          status: UserStatus.online, activity: ActivityBuilder("the chat go by...", ActivityType.watching)));
    });

    onyxChat = OnyxChat(gateway, prefix: ".");
    onyxChat.addCommandList([GenerateCommand()]);

    gateway.eventsWs.onMessageReceived.listen((event) {
      if (event.message.author.bot) return;

      onyxChat.dispatchIMessage(event.message);
      cc.onMessageEvent(event);
    });
  }
}

// class CCBot extends Nyxx {
//   final CCDatabase database;
//   late List<Snowflake> admins = [];
//   HashMap<Snowflake, GuildListener> guildListeners = HashMap();

//   CCBot(String token, int intents, this.database,
//       {ClientOptions? options,
//       CacheOptions? cacheOptions,
//       bool ignoreExceptions = true,
//       bool useDefaultLogger = true,
//       admins})
//       : super(token, intents,
//             options: options,
//             cacheOptions: cacheOptions,
//             ignoreExceptions: ignoreExceptions,
//             useDefaultLogger: useDefaultLogger);

//   bool checkForGuildListener(Snowflake guildID) {
//     return guildListeners.containsKey(guildID);
//   }

//   void addGuildListener(Snowflake guildID, GuildListener gl) {
//     guildListeners.putIfAbsent(guildID, () => gl);
//   }

//   void removeGuildListener(Snowflake guildID, GuildListener gl) {
//     guildListeners.removeWhere((key, value) => key == guildID);
//   }
// }
