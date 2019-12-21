import 'package:nyxx/nyxx.dart';
import 'package:nyxx/Vm.dart';
import 'package:nyxx/commands.dart' as cmd;

//commands
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
  prefixHandler = cmd.CommandsFramework(bot, prefix: prefix)
    ..discoverCommands();
  
  var mentionHandler = cmd.CommandsFramework(bot, prefix: mention)
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
  });
}
