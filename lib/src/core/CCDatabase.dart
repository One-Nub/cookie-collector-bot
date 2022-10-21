import 'dart:async';
import 'dart:math';

import 'package:mysql_client/mysql_client.dart';

class CCDatabase {
  static final CCDatabase _instance = CCDatabase._init();
  CCDatabase._init();

  late final MySQLConnectionPool pool;

  factory CCDatabase(
      {required bool initializing,
      String? username,
      String? password,
      String? host,
      String? databaseName,
      int port = 3306,
      int maxConnections = 10}) {
    if (initializing) {
      _instance.pool = MySQLConnectionPool(
          host: host!,
          port: port,
          userName: username!,
          password: password,
          maxConnections: maxConnections,
          databaseName: databaseName,
          secure: false);
    }
    return _instance;
  }

  /// Shouldn't need to be called ever
  Future<void> initializeTables() async {
    String guildsTable = "CREATE TABLE IF NOT EXISTS guilds ( "
        "id BIGINT NOT NULL PRIMARY KEY, "
        "prefix TINYTEXT DEFAULT '.')";

    String userGuildsTable = "CREATE TABLE IF NOT EXISTS users_guilds ( "
        "user_id BIGINT NOT NULL, "
        "guild_id BIGINT NOT NULL, "
        "cookies INT DEFAULT 0, "
        "lifetime_cookies INT DEFAULT 0, "
        "partner_id BIGINT DEFAULT 0, "
        "CONSTRAINT `pk_users_guilds`  "
        "PRIMARY KEY (user_id, guild_id),"
        "CONSTRAINT `fk_guild_id` "
        "FOREIGN KEY (guild_id) REFERENCES guilds (id)"
        "ON DELETE CASCADE)";

    String ignoredChannelTable = "CREATE TABLE IF NOT EXISTS ignored_channels ( "
        "channel_id BIGINT NOT NULL, "
        "guild_id BIGINT NOT NULL, "
        "CONSTRAINT `fk_ic_guild_id`"
        "FOREIGN KEY (guild_id) REFERENCES guilds (id)"
        "ON DELETE CASCADE)";

    pool.transactional((conn) async {
      await conn.execute(guildsTable);
      await conn.execute(userGuildsTable);
      await conn.execute(ignoredChannelTable);
    });
  }

  ///Adds a guild to the guilds table
  Future<void> addGuildRow(int guildID) async {
    await pool.execute("INSERT INTO guilds (id) VALUES ($guildID) "
        "ON DUPLICATE KEY UPDATE id=id");
  }

  Future<Iterator<ResultSetRow>> leaderboardSelection(int guildID,
      {int pageNumber = 0, int pageEntryMax = 15}) async {
    String query = "SELECT * FROM ("
        "SELECT ROW_NUMBER() OVER(ORDER BY cookies DESC) "
        "AS row_num, user_id, cookies "
        "FROM users_guilds WHERE (guild_id = $guildID) ORDER BY row_num) rnt "
        "WHERE rnt.row_num > ${pageNumber * pageEntryMax} LIMIT $pageEntryMax";

    var result = await pool.execute(query);
    return result.rows.iterator;
  }

  Future<IResultSet?> getUserGuildData(int userID, int guildID) async {
    IResultSet? returnRow = null;
    String query = "SELECT * FROM users_guilds "
        "WHERE user_id = $userID AND guild_id = $guildID";
    var result = await pool.execute(query);
    if (result.isNotEmpty) {
      returnRow = result;
    }
    return returnRow;
  }

  Future<IResultSet?> getRankedUserGuildData(int userID, int guildID) async {
    IResultSet? returnRow = null;
    String query = "SELECT * FROM ("
        "SELECT ROW_NUMBER() OVER(ORDER BY cookies DESC) "
        "AS row_num, user_id, cookies "
        "FROM users_guilds WHERE (guild_id = $guildID) ORDER BY row_num) rnt "
        "WHERE user_id = $userID";
    var results = await pool.execute(query);
    if (results.isNotEmpty) {
      returnRow = results;
    }
    return returnRow;
  }

  Future<IResultSet?> getRandomUserToRob(int guildID, int excludeUserID, int minCookieCount) async {
    Random rand = Random.secure();

    String query = "SELECT * FROM users_guilds "
        "WHERE cookies >= $minCookieCount AND user_id != $excludeUserID "
        "AND guild_id = $guildID "
        "ORDER BY RAND(${rand.nextInt(255)}) LIMIT 1";
    IResultSet result = await pool.execute(query);

    if (result.isNotEmpty) {
      return result;
    } else {
      return null;
    }
  }

  Future<void> addCookies(int userID, int numCookies, int guildID) async {
    await addGuildRow(guildID);
    String query = "INSERT INTO users_guilds (user_id, guild_id, cookies) "
        "VALUES ($userID, $guildID, $numCookies)"
        "ON DUPLICATE KEY UPDATE cookies = cookies + $numCookies";
    await pool.execute(query);
  }

  Future<void> removeCookies(int userID, int numCookies, int guildID) async {
    await addGuildRow(guildID);
    String query = "INSERT INTO users_guilds (user_id, guild_id, cookies) "
        "VALUES ($userID, $guildID, -$numCookies)"
        "ON DUPLICATE KEY UPDATE cookies = cookies - $numCookies";
    await pool.execute(query);
  }

  Future<void> addLifetimeCookies(int userID, int numCookies, int guildID) async {
    await addGuildRow(guildID);
    String query = "INSERT INTO users_guilds (user_id, guild_id, lifetime_cookies) "
        "VALUES ($userID, $guildID, $numCookies)"
        "ON DUPLICATE KEY UPDATE lifetime_cookies = lifetime_cookies + $numCookies";
    await pool.execute(query);
  }

  Future<int> getCookieCount(int userID, int guildID) async {
    int numCookies = 0;
    String query = "SELECT cookies FROM users_guilds "
        "WHERE (user_id = $userID AND guild_id = $guildID)";
    IResultSet resultSet = await pool.execute(query);
    if (resultSet.isNotEmpty) {
      var resultRow = resultSet.rows.first;
      numCookies = resultRow.typedAssoc()["cookies"];
    }
    return numCookies;
  }

  Future<String> getPrefix(int guildID) async {
    String query = "SELECT prefix FROM guilds WHERE id = $guildID";
    IResultSet resultSet = await pool.execute(query);

    String prefix = ".";
    if (resultSet.isNotEmpty) {
      var resultRow = resultSet.rows.first;
      prefix = resultRow.assoc()["prefix"]!;
    }
    return prefix;
  }

  Future<void> setPrefix(int guildID, String prefix) async {
    String query = "UPDATE guilds "
        "SET prefix = :prefix "
        "WHERE id = $guildID";
    pool.execute(query, {"prefix": prefix});
  }
}
