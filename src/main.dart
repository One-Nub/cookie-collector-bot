import 'dart:io';

import 'package:safe_config/safe_config.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx/Vm.dart';
import 'package:nyxx.commands/commands.dart' as cmd; //rewrite locally cloned

import 'cmds/commands_list.dart'; //ignore: unused_import
import 'database_helper.dart';

Nyxx bot;
var prefixHandler;
var db;
List<Snowflake> admins = [Snowflake(156872400145874944),
    Snowflake(194962036784889858)];

Future<void> main() async {
  var timer = Stopwatch();
  timer.start();

  var botConfig = await new BotConfig('src/config.yaml');

  String token = botConfig.token;
  String prefix = botConfig.prefix;
  String mention = "";

  db = database_helper();
  await db.setup_config(
      botConfig.database_config.username, 
      botConfig.database_config.password, 
      botConfig.database_config.host, 
      botConfig.database_config.databaseName, 
      botConfig.database_config.port);
  
  print("Database connection available?: ${await db.test_connection()}");

  bot = NyxxVm(token);
  prefixHandler = cmd.CommandsFramework(bot, prefix: prefix, admins: admins)
    ..discoverCommands();
  var mentionHandler =
      cmd.CommandsFramework(bot, prefix: mention, admins: admins)
        ..discoverCommands();

  await bot.onReady.listen((e) {
    timer.stop();
    print("Ready in ${bot.guilds.count} guild(s) as "
        "${bot.self.username + "#" + bot.self.discriminator}");
    print("It took ${timer.elapsed.inSeconds} seconds to start up");

    var presence =
        Presence.of("with some cookies", type: PresenceType.game);
    bot.self.setPresence(game: presence);

    mention = bot.self.mention;
    mentionHandler.prefix = mention;
    cookieTriggerListener();
  });

  bot.onGuildCreate.listen((e) async {
    var guildID = e.guild.id.toInt();
    await db.create_table(guildID);
    print("Joined guild - ${e.guild.name} with ID of $guildID at ${DateTime.now()}");
  });
}

class BotConfig extends Configuration {
  BotConfig(String fileName) : super.fromFile(File(fileName));

  String token;
  String prefix;
  DatabaseConfiguration database_config;
}
