import 'main.dart' as main;
import 'package:nyxx/nyxx.dart';

void guildCreateListener() async {
  main.bot.onGuildCreate.listen((e) async {
    var guildID = e.guild.id.toInt();
    await main.db.create_table(guildID);
    print("Joined guild - ${e.guild.name} with ID of $guildID at ${DateTime.now()}");
  });
}

void shardConnectActions() async {
  main.bot.shard.onReady.listen((e) async {
    //Set the presence
    main.bot.shard.setPresence(game:
      Presence.of("with some cookies", type: PresenceType.game));
  });
}
