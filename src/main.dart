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

Future<void> main() async {
  var timer = Stopwatch();
  timer.start();

  var botConfig = await new BotConfig('src/config.yaml');

  String token = botConfig.token;
  String prefix = botConfig.prefix;
  String mention = "";
  List<Snowflake> admins = [Snowflake(156872400145874944),
    Snowflake(194962036784889858)];

  db = database_helper();
  await db.connect(
      botConfig.database_config.username, 
      botConfig.database_config.password, 
      botConfig.database_config.host, 
      botConfig.database_config.databaseName, 
      botConfig.database_config.port);

  bot = NyxxVm(token);
  prefixHandler = cmd.CommandsFramework(bot, prefix: prefix, admins: admins)
    ..discoverCommands();
  var mentionHandler =
      cmd.CommandsFramework(bot, prefix: mention, admins: admins)
        ..discoverCommands();

  bot.onReady.listen((e) {
    timer.stop();
    print("Ready in ${bot.guilds.count} guild(s) as "
        "${bot.self.username + "#" + bot.self.discriminator}");
    print("It took ${timer.elapsed.inSeconds} seconds to start up");

    var presence =
        Presence.of("to some happy tunes", type: PresenceType.listening);
    bot.self.setPresence(game: presence);

    mention = bot.self.mention;
    mentionHandler.prefix = mention;
    cookieTriggerListener();
  });

  bot.onGuildCreate.listen((e) async {
    var guildID = e.guild.id.toInt();
    await db.create_table(guildID);
    print("Joined guild - ${e.guild.name} with ID of $guildID");
  });
}

class BotConfig extends Configuration {
  BotConfig(String fileName) : super.fromFile(File(fileName));

  String token;
  String prefix;
  DatabaseConfiguration database_config;
}
