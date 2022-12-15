import 'package:nyxx/nyxx.dart';

import '../core/CCDatabase.dart';

void onGuildJoinEvent(IGuildCreateEvent event) async {
  if ((await event.guild.selfMember.getOrDownload())
      .joinedAt
      .isBefore(DateTime.now().toUtc().subtract(Duration(days: 1)))) {
    /// We were already in this guild before the past day so there's no need to generate the default
    /// database information for it.
    return;
  }

  CCDatabase database = CCDatabase(initializing: false);
  database.addGuildRow(event.guild.id.id);
  print("Guild joined: ${event.guild.id} - ${event.guild.name}");
}
