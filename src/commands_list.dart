library commands;

//Imports that the commands may need
import 'dart:io';
import 'dart:math';
import 'dart:async';

//Nyxx related
import 'package:nyxx.commands/commands.dart';
import 'package:nyxx/nyxx.dart';
import 'main.dart';

//Utility files
part 'processors.dart';

//Normal commands below here
part 'cmds/chat_collector.dart';
part 'cmds/daily.dart';
part 'cmds/eat.dart';
part 'cmds/give.dart';
part 'cmds/help.dart';
part 'cmds/info.dart';
part 'cmds/leaderboard.dart';
part 'cmds/ping.dart';
part 'cmds/rob.dart';
part 'cmds/say.dart';
part 'cmds/stats.dart';

//Admin commands below here
part 'admin_cmds/generate.dart';
