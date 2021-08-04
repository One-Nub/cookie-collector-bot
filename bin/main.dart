import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commander/commander.dart';
import 'package:nyxx_interactions/interactions.dart';
import 'package:toml/toml.dart';

import 'internal/CCDatabase.dart';
import 'commands/commands_lib.dart';
import 'framework/framework_lib.dart';

late final CCBot bot;
late final Commander cmdr;
late final Interactions interactions;
late CCDatabase db;

Future<void> main() async {
  Stopwatch startupTimer = Stopwatch();
  startupTimer.start();

  Logger.root.onRecord.listen((LogRecord rec) {
    print("[${rec.time}] [${rec.level.name}] [${rec.loggerName}] ${rec.message}");
  });

  Level startup = Level("START", 850);
  var startLogger = Logger("STARTUP");

  //Load bot config.
  TomlDocument tomlDocument = await TomlDocument.load("src/config.toml");
  Map tomlConfig = tomlDocument.toMap();
  Map databaseConfig = tomlConfig["database"];

  //Load bot admin IDs
  final List<Snowflake> admins = [];
  List configAdmins = tomlConfig["admins"];
  for(int value in configAdmins) {
    admins.add(Snowflake(value));
  }

  //Load database config (& validate)
  db = CCDatabase(databaseConfig["username"],
    databaseConfig["password"],
    databaseConfig["host"],
    databaseConfig["databaseName"],
    databaseConfig["port"]);

  var verifyConnection = await db.dbConnection();
  verifyConnection.close();

  db.initializeTables();

  // int gatewayIntents =
  //   GatewayIntents.directMessages + GatewayIntents.guildMessageReactions +
  //   GatewayIntents.guildMessages + GatewayIntents.guilds;

  int allUnpriv = GatewayIntents.allUnprivileged;

  ClientOptions clOpts = ClientOptions()
    ..initialPresence = PresenceBuilder.of(game: Activity.of("the chat go by", type: ActivityType.from(3)));

  CacheOptions cacheOptions = CacheOptions()
    ..memberCachePolicyLocation = CachePolicyLocation.all()
    ..userCachePolicyLocation = CachePolicyLocation.all();

  bot = CCBot(tomlConfig["token"], allUnpriv, options: clOpts,
    defaultLoggerLogLevel: Level.INFO, useDefaultLogger: false, admins: admins,
    cacheOptions: cacheOptions);

  interactions = Interactions(bot);

  //Required for cooldown currently
  Daily daily = Daily(db);
  Leaderboard leaderboard = Leaderboard(db, interactions);
  Rob rob = Rob(db);

  cmdr = Commander(bot, prefixHandler: (Message msg) => prefixHandler(msg, tomlConfig["default_prefix"]))
    ..registerCommand("daily", daily.commandFunction, beforeHandler: daily.preRunChecks)
    ..registerCommand("eat", Eat(db).commandFunction, beforeHandler: Eat.preRunChecks)
    ..registerCommand("generate", Generate(db).argumentParser, beforeHandler: Generate.preRunChecks)
    ..registerCommand("give", Give(db).argumentParser, beforeHandler: (ctx) => Give.preRunChecks(ctx, db))
    ..registerCommand("info", Info(db).commandFunction)
    ..registerCommand("status", Info(db).commandFunction)
    ..registerCommand("leaderboard", leaderboard.commandFunction, beforeHandler: leaderboard.preRunChecks)
    ..registerCommand("lb", leaderboard.commandFunction, beforeHandler: leaderboard.preRunChecks)
    ..registerCommand("ping", Ping().commandFunction, beforeHandler: Ping.preRunChecks)
    ..registerCommand("rob", rob.argumentParser, beforeHandler: (ctx) => rob.preRunChecks(ctx, db))
    ..registerCommand("say", Say().argumentParser, beforeHandler: (ctx) => Say.preRunChecks(ctx, admins))
    ..registerCommand("bal", Stats(db).argumentParser, beforeHandler: Stats.preRunChecks)
    ..registerCommand("stats", Stats(db).argumentParser, beforeHandler: Stats.preRunChecks);


  bot.onReady.listen((event) {
    startupTimer.stop();
    startLogger.log(startup, "Ready, it took ${startupTimer.elapsed.inSeconds} "
      "second(s) to start.");
  });

  bot.onGuildCreate.listen((event) {
    Logger("Guild Join")
      .log(Level.INFO, "Guild \"${event.guild.name}\":${event.guild.id} "
        "was loaded at ${DateTime.now()}");
    db.addGuildRow(event.guild.id.id);
    if(!bot.checkForGuildListener(event.guild.id)) {
      bot.addGuildListener(event.guild.id, GuildListener(event.guild));
    }
  });

  // Clears the users cache on a bi-daily basis.
  Timer.periodic(Duration(days: 2), (timer) {
    bot.users.dispose();
  });
}

Future<String?> prefixHandler(Message message, String defaultPrefix) async {
  if(message.author.bot) {
    return null;
  }

  String mention = bot.self.mention;
  if(message.content.startsWith(mention) && message.runtimeType != DMMessage)
    return mention;
  else if(message.runtimeType == GuildMessage) {
    GuildMessage guildMessage = message as GuildMessage;
    String guildPrefix = await db.getPrefix(guildMessage.guild.id.id);
    if(message.content.startsWith(guildPrefix))
      return guildPrefix;
  }
}