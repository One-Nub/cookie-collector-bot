import 'package:nyxx/nyxx.dart';

import '../core/CCDatabase.dart';

void onLeaveEvent(IGuildMemberRemoveEvent event) async {
  const int cookiesToRemove = 100;
  if (event.user.bot) return;

  int userID = event.user.id.id;
  int guildID = event.guild.id.id;

  CCDatabase db = CCDatabase(initializing: false);
  var databaseResult = await db.getUserGuildData(userID, guildID);
  if (databaseResult == null || databaseResult.rows.isEmpty) {
    return;
  }

  Map<String, dynamic> userData = databaseResult.rows.first.typedAssoc();
  int userCookies = userData["cookies"];

  if (userCookies - cookiesToRemove < 0) {
    await db.removeCookies(userID, userCookies, guildID);
  } else {
    await db.removeCookies(userID, cookiesToRemove, guildID);
  }
}
