import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:logging/logging.dart';
import 'package:onyx_chat/onyx_chat.dart';

import 'package:cookie_collector_bot/modules.dart';

class CCBot {
  late final String token;
  late final INyxxWebsocket gateway;
  late final IInteractions interactions;
  late final OnyxChat onyxChat;

  late final List<Snowflake> adminList;

  static final CCBot _instance = CCBot._init();

  CCBot._init();

  factory CCBot({String? token, List<Snowflake>? adminList}) {
    if (token != null) _instance.token = token;
    if (adminList != null) _instance.adminList = adminList;

    return _instance;
  }

  void startGateway() async {
    CacheOptions cacheOptions = CacheOptions()
      ..memberCachePolicyLocation = CachePolicyLocation.all()
      ..userCachePolicyLocation = CachePolicyLocation.all();

    gateway = NyxxFactory.createNyxxWebsocket(
        token, GatewayIntents.messageContent | GatewayIntents.guildMessages | GatewayIntents.guildMembers,
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
    onyxChat.addCommandList([
      GenerateCommand(),
      SayCommand(),
      DailyCommand(),
      EatCommand(),
      GiveCommand(),
      HelpCommand(),
      InfoCommand(),
      LeaderboardCommand(),
      PingCommand(),
      RobCommand(),
      StatsCommands()
    ]);

    gateway.eventsWs.onMessageReceived.listen((event) {
      if (event.message.author.bot) return;

      /// for custom prefix, here you would get the prefix for the server from the db
      /// and pass the prefix param over the dispatch msg
      onyxChat.dispatchIMessage(event.message);
      onMessageEvent(event);
    });

    gateway.eventsWs.onGuildMemberRemove.listen((event) => onLeaveEvent(event));
    gateway.eventsWs.onGuildCreate.listen((event) => onGuildJoinEvent(event));
  }

  void startInteractions() async {
    interactions = IInteractions.create(WebsocketInteractionBackend(gateway));
  }
}
