import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart' as resp_server;

class CCRedis {
  static final CCRedis _instance = CCRedis._init();
  CCRedis._init();

  late final RespClient cacheConnection;

  factory CCRedis() {
    return _instance;
  }

  static Future<CCRedis> init({String host = "localhost", int port = 6379, String? auth}) async {
    var serverConnection = await resp_server.connectSocket(host, port: port);
    RespClient client = RespClient(serverConnection);
    _instance.cacheConnection = client;

    if (auth != null) {
      RespCommandsTier2(client).auth(auth);
    }

    return _instance;
  }

  Future<Map<String, dynamic>> getDailyStreakData(int guildID, int userID) async {
    var client = RespCommandsTier2(cacheConnection);
    return await client.hgetall("streak-$guildID-$userID");
  }

  /// Increase the streak for a [userID] in [guildID] when the last user collection time is [luc].
  Future<int> increaseDailyStreak(int guildID, int userID, DateTime luc) async {
    var client = RespCommandsTier2(cacheConnection);
    String key = "streak-$guildID-$userID";
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
}
