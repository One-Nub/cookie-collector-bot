import 'package:mysql_client/mysql_client.dart';
import 'package:nyxx/nyxx.dart';

import '../core/CCDatabase.dart';

void onGuildJoinEvent(IGuildCreateEvent event) async {
  print("Guild create event for: ${event.guild.id} - ${event.guild.name}");
  CCDatabase database = CCDatabase(initializing: false);

  IResultSet result =
      await database.pool.execute("SELECT count(*) FROM guilds WHERE id IN (${event.guild.id.id})");
  int count = result.rows.first.typedAssoc()["count(*)"];

  if (count == 0) {
    database.addGuildRow(event.guild.id.id);
    print("Guild added to the database: ${event.guild.id} - ${event.guild.name}");
  }
}
