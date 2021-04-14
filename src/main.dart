import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commander/commander.dart';
import 'package:toml/toml.dart';

import 'internal/CCDatabase.dart';
import 'commands/commands_lib.dart';
import 'framework/framework_lib.dart';

late final CCBot bot;
late final Commander cmdr;
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
    ..initialPresence = PresenceBuilder.of(game: Activity.of("the development game"));

  bot = CCBot(tomlConfig["token"], allUnpriv, options: clOpts,
    defaultLoggerLogLevel: Level.INFO, useDefaultLogger: false, admins: admins);

  cmdr = Commander(bot, prefixHandler: (Message msg) => prefixHandler(msg, tomlConfig["default_prefix"]))
    ..registerCommand("daily", Daily(db).commandFunction, beforeHandler: Daily.preRunChecks)
    ..registerCommand("eat", Eat(db).commandFunction, beforeHandler: Eat.preRunChecks)
    ..registerCommand("generate", Generate(db).argumentParser, beforeHandler: Generate.preRunChecks)
    ..registerCommand("info", Info(db).commandFunction)
    ..registerCommand("status", Info(db).commandFunction)
    ..registerCommand("leaderboard", Leaderboard(db).commandFunction, beforeHandler: Leaderboard.preRunChecks)
    ..registerCommand("lb", Leaderboard(db).commandFunction, beforeHandler: Leaderboard.preRunChecks)
    ..registerCommand("ping", Ping().commandFunction, beforeHandler: Ping.preRunChecks)
    ..registerCommand("say", Say().argumentParser, beforeHandler: (ctx) => Say.preRunChecks(ctx, admins))
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
    bot.addGuildListener(GuildListener(event.guild));
  });
}

Future<String?> prefixHandler(Message message, String defaultPrefix) async {
  String mention = bot.self.mention;
  if(message.content.startsWith(mention))
    return mention;
  else if(message.content.startsWith(defaultPrefix))
    return defaultPrefix;
}
