import 'package:nyxx/nyxx.dart';
import 'package:logging/logging.dart';

import '../new_modules/chat_collection/on_message.dart';

class CCBot {
  final String token;
  late final INyxxWebsocket gateway;

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
      ..registerPlugin(IgnoreExceptions());

    gateway.eventsWs.onReady.listen((event) {
      gateway.setPresence(PresenceBuilder.of(
          status: UserStatus.online, activity: ActivityBuilder("the chat go by...", ActivityType.watching)));
    });

    gateway.eventsWs.onMessageReceived.listen((event) {
      onMessageEvent(event);
    });

    await gateway.connect();
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
