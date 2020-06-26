import 'dart:io';

import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx.commander/commander.dart';
import 'package:yaml/yaml.dart';

import 'CCDatabase.dart';
import 'commands/commands_lib.dart';

late final Nyxx bot;
late final Commander cmdr;
late CCDatabase db;
final List<Snowflake> admins = [];

Future<void> main() async {
  Stopwatch startupTimer = Stopwatch();
  startupTimer.start();

  setupDefaultLogging(Level.INFO);
  Level startup = Level("START", 850);
  var startLogger = Logger("STARTUP");
  
  //Load config.
  YamlMap botConfig = loadYaml(File('src/config.yaml').readAsStringSync());
  final token = botConfig["token"];
  final defaultPrefix = botConfig["default_prefix"];

  YamlList configAdmins = botConfig["admins"];
  for(int value in configAdmins) {
    admins.add(Snowflake(value));
  }

  YamlMap dbConfig = botConfig["database_config"];
  db = CCDatabase(dbConfig["username"], 
    dbConfig["password"], 
    dbConfig["host"], 
    dbConfig["databaseName"], 
    dbConfig["port"]);

  var verifyConnection = await db.dbConnection();
  verifyConnection.close();

  ClientOptions clOpts = ClientOptions()
    ..initialPresence = PresenceBuilder.of(game: Activity.of("the development game"));

  bot = Nyxx(token, options: clOpts);

  cmdr = Commander(bot, prefixHandler: (Message msg) => prefixHandler(msg, defaultPrefix))
    ..registerCommand("eat", Eat(db).commandFunction, beforeHandler: Eat.preRunChecks)
    ..registerCommand("generate", Generate(db).argumentParser, beforeHandler: Generate.preRunChecks)
    ..registerCommand("leaderboard", Leaderboard(db).commandFunction, beforeHandler: Leaderboard.preRunChecks)
    ..registerCommand("lb", Leaderboard(db).commandFunction, beforeHandler: Leaderboard.preRunChecks)
    ..registerCommand("ping", Ping().commandFunction, beforeHandler: Ping.preRunChecks)
    ..registerCommand("say", Say().argParser, beforeHandler: (ctx) => Say.preRunChecks(ctx, admins))
    ..registerCommand("stats", Stats(db).argumentParser, beforeHandler: Stats.preRunChecks);

  bot.onReady.listen((event) {
    startupTimer.stop();
    startLogger.log(startup, "Ready, it took ${startupTimer.elapsed.inSeconds} "
      "second(s) to start.");
  });

  bot.onGuildCreate.listen((event) {
    Logger("Guild Join")
      .log(Level.INFO, "Guild ${event.guild.name}:${event.guild.id} "
        "was loaded at ${DateTime.now()}");
    db.createGuildTable(event.guild.id.id);
  });
}

Future<String?> prefixHandler(Message message, String defaultPrefix) async {
  String mention = bot.self.mention;
  if(message.content.startsWith(mention))
    return mention;
  else if(message.content.startsWith(defaultPrefix))
    return defaultPrefix;
}
