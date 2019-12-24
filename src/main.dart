import 'package:nyxx/nyxx.dart';
import 'package:nyxx/Vm.dart';
import 'package:nyxx.commands/commands.dart' as cmd; //rewrite locally cloned
import 'cmds/commands_list.dart'; //ignore: unused_import

Nyxx bot;
var prefixHandler;

void main() {
  var timer = Stopwatch();
  timer.start();

  String token = "";
  String prefix = ".";
  String mention = "";

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

    var presence = Presence.of("${bot.guilds.count} guild(s)", type: PresenceType(3));
    bot.self.setPresence(game: presence);

    mention = bot.self.mention;
    mentionHandler.prefix = mention;
    cookieTriggerListener();
  });
}
