import 'package:nyxx/nyxx.dart';
import 'package:nyxx/Vm.dart';
import 'package:nyxx/commands.dart';

//commands
import 'cmds/commands_list.dart'; //ignore: unused_import

Nyxx bot;
var cmdFramework;

void main() {
  var timer = Stopwatch();
  timer.start();

  var token = "";
  var prefix = ".";

  bot = NyxxVm(token);
  cmdFramework = CommandsFramework(bot, prefix: prefix)
    ..discoverCommands();
  
  bot.onReady.listen((e) {
    timer.stop();
    print("Ready in ${bot.guilds.count} guild(s) as "
      "${bot.self.username + "#" + bot.self.discriminator}");
    print("It took ${timer.elapsed.inSeconds} seconds to start up");

    var presence = Presence.of("${bot.guilds.count} guild(s)", type: PresenceType(3));
    bot.self.setPresence(game: presence);
  });
}
