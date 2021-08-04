import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commander/commander.dart';

import '../../core/CCDatabase.dart';

class Eat {
  CCDatabase _database;
  Eat(this._database);

  static bool preRunChecks(CommandContext ctx) {
    if(ctx.guild == null) return false;
    return true;
  }

  Future<void> commandFunction(CommandContext ctx, String message) async {
    await _database.removeCookies(ctx.author.id.id, 1, ctx.guild!.id.id);
    AllowedMentions _mentions = AllowedMentions()..allow(reply:false);
    ctx.reply(MessageBuilder.content("You ate 1 cookie! very yummy :cookie:")
      ..allowedMentions = _mentions);
  }
}
