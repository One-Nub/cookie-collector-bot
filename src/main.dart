import 'dart:io';

import 'package:safe_config/safe_config.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx/Vm.dart';
import 'package:nyxx.commands/commands.dart' as cmd; //rewrite locally cloned

import 'cmds/commands_list.dart'; //ignore: unused_import

Nyxx bot;
var prefixHandler;

Future<void> main() async {
  var timer = Stopwatch();
  timer.start();

  var botConfig = new BotConfig('src/config.yaml');

  String token = botConfig.token;
  String prefix = botConfig.prefix;
  String mention= "";

  bot = NyxxVm(token);
  List<Snowflake> admins = [Snowflake(156872400145874944)];
  prefixHandler = cmd.CommandsFramework(bot, prefix: prefix, admins: admins)
    ..discoverCommands();
  
  var mentionHandler = cmd.CommandsFramework(bot, prefix: mention, admins: admins)
    ..discoverCommands();
  
  bot.onReady.listen((e) {
    timer.stop();
    print("Ready in ${bot.guilds.count} guild(s) as "
      "${bot.self.username + "#" + bot.self.discriminator}");
    print("It took ${timer.elapsed.inSeconds} seconds to start up");

    var presence = Presence.of("to some happy tunes", type: PresenceType.listening);
    bot.self.setPresence(game: presence);

    mention = bot.self.mention;
    mentionHandler.prefix = mention;
    cookieTriggerListener();
  });
}

class BotConfig extends Configuration {
  BotConfig(String fileName) : super.fromFile(File(fileName));

  String token;
  String prefix;
  DatabaseConfiguration database_config;
}