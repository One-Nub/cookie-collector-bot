import 'package:cookie_collector_bot/core.dart';
import 'package:nyxx/nyxx.dart';
import 'package:toml/toml.dart';

void main() async {
  //Load bot config.
  TomlDocument tomlDocument = await TomlDocument.load("bin/config.toml");
  Map tomlConfig = tomlDocument.toMap();
  Map databaseConfig = tomlConfig["database"];

  //Load bot admin IDs
  final List<Snowflake> admins = [];
  List configAdmins = tomlConfig["admins"];
  for (int value in configAdmins) {
    admins.add(Snowflake(value));
  }

  CCDatabase(
      initializing: true,
      username: databaseConfig["username"],
      password: databaseConfig["password"],
      host: databaseConfig["host"],
      databaseName: databaseConfig["databaseName"],
      port: databaseConfig["port"]);

  CCBot bot = CCBot(token: tomlConfig["token"]);
  bot.startGateway();
  bot.startInteractions();
}
