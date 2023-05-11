import 'dart:io';

import 'package:logging/logging.dart';
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart' as resp_server;

Logger _logger = Logger("CCRedis");

class CCRedis {
  static final CCRedis _instance = CCRedis._init();
  CCRedis._init();

  late final RespClient cacheConnection;

  factory CCRedis() {
    return _instance;
  }

  static Future<CCRedis> init({String host = "localhost", int port = 6379, String? auth}) async {
    bool connected = false;
    int retryCount = 0;

    connected = await handleConnect(host: host, port: port, auth: auth);

    while (!connected && retryCount <= 5) {
      _logger.warning("Could not connect to the Redis server. Retry attempt: $retryCount");
      connected = await handleConnect(host: host, port: port, auth: auth);

      // Increase how long it takes before retrying up to 12 seconds at most.
      await Future.delayed(Duration(seconds: 2 * (retryCount += 1)));
    }

    if (!connected) {
      // Stop execution, couldn't connect to redis. This will cause the program to restart though, which
      // when not handled properly, can easily lead to the daily session count for Discord being
      // reached (when program is set tp auto-restart).
      _logger.shout("Execution is being terminated. Redis connection could not be made.");

      // Give logger a chance to shout before exiting.
      await Future.delayed(Duration(seconds: 1));
      exit(1);
    }

    return _instance;
  }

  static Future<bool> handleConnect({String host = "localhost", int port = 6379, String? auth}) async {
    try {
      var serverConnection = await resp_server.connectSocket(host, port: port);
      RespClient client = RespClient(serverConnection);
      _instance.cacheConnection = client;

      if (auth != null) {
        RespCommandsTier2(client).auth(auth);
      }

      return true;
    } on SocketException {
      return false;
    }
  }

  Future<Map<String, dynamic>> getDailyStreakData(int guildID, int userID) async {
    var client = RespCommandsTier2(cacheConnection);
    return await client.hgetall("daily-streak-$guildID-$userID");
  }

  /// Increase the streak for a [userID] in [guildID] when the last user collection time is [luc].
  Future<int> increaseDailyStreak(int guildID, int userID, DateTime luc) async {
    var client = RespCommandsTier2(cacheConnection);
    String key = "daily-streak-$guildID-$userID";
    var duration = await client.tier1.tier0.execute(["HINCRBY", key, "streak-duration", 1]);
    client.hset(key, "lastUserCollection", luc.millisecondsSinceEpoch);
    client.pexpire(key, Duration(days: 2));

    return (duration.toInteger()).payload;
  }

  Future<int?> getRobCooldown(int guildID, int userID) async {
    var client = RespCommandsTier2(cacheConnection);
    String key = "rob-cooldowns-$guildID-$userID";

    String? result = await client.get(key);
    if (result != null) {
      return int.tryParse(result);
    } else {
      return null;
    }
  }

  Future<void> setRobCooldown(int guildID, int userID, DateTime expiryTime, {Duration? ttl}) async {
    var client = RespCommandsTier2(cacheConnection);
    String key = "rob-cooldowns-$guildID-$userID";

    await client.set(key, expiryTime.millisecondsSinceEpoch);
    if (ttl != null) {
      client.pexpire(key, ttl);
    } else {
      /// Expire key after a day since by then it should be expired regardless.
      client.pexpire(key, Duration(days: 1));
    }
  }

  Future<Map<String, dynamic>> getChannelStreakData(int channelID) async {
    var client = RespCommandsTier2(cacheConnection);
    return await client.hgetall("channel-streak-$channelID");
  }

  Future<int> increaseChannelStreak(int channelID) async {
    var client = RespCommandsTier2(cacheConnection);
    String key = "channel-streak-$channelID";

    var streakLength = await client.tier1.tier0.execute(["HINCRBY", key, "streak-duration", 1]);
    // Expire after a day since by that point the streak has gone stale.
    client.pexpire(key, Duration(days: 1));

    return (streakLength.toInteger()).payload;
  }

  Future<void> startChannelStreak(int channelID, int userID, {int baseAmount = 0}) async {
    var client = RespCommandsTier2(cacheConnection);
    String key = "channel-streak-$channelID";

    client.hset(key, "streak-duration", baseAmount);
    client.hset(key, "userID", userID);
    // Expire after a day since by that point the streak has gone stale.
    client.pexpire(key, Duration(days: 1));
  }
}
