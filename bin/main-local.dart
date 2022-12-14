import 'dart:convert';

import 'package:cookie_collector_bot/core.dart';
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load(['bin/.env']);

  //Load bot admin IDs
  final List<Snowflake> admins = [];
  List configAdmins = jsonDecode(env["ADMINS"]!);
  for (int value in configAdmins) {
    admins.add(Snowflake(value));
  }

  CCDatabase(
      initializing: true,
      username: env["DB_USER"],
      password: env["DB_PASS"],
      host: env["DB_HOST"],
      databaseName: env["DB_NAME"],
      port: int.parse(env["DB_PORT"]!));

  CCRedis.init(host: env["REDIS_HOST"]!, port: int.parse(env["REDIS_PORT"]!), auth: env["REDIS_PASS"]);

  CCBot bot = CCBot(token: env["TOKEN"], adminList: admins);
  bot.startGateway();
  bot.startInteractions();
}
