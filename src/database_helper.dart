import 'dart:async';

import 'package:mysql1/mysql1.dart';

class database_helper {
  var user_config;

  Future<void> setup_config(String username, String password,
      String host, String database, int port) async {
    user_config = ConnectionSettings(
        user: username,
        password: password,
        host: host,
        db: database,
        port: port);
  }

  Future<MySqlConnection> dbConnect(ConnectionSettings user_config) async {
    return await MySqlConnection.connect(user_config);
  }

  Future<bool> test_connection() async {
      var tempConnect = await dbConnect(user_config).timeout(Duration(seconds: 15))
          .catchError((TimeoutException error) {
            print("Didn't connect in time");
            return false;
          });
        tempConnect.close();
        return true;
      }

  Future<void> add_cookies(int userID, int numCookies, int guildID) async {
    //No user input is ever used here so sanitization isn't as concerning, though
    //typically good in practice
    var connection = await dbConnect(user_config);
    var queryExistance = await connection.query(
        "SELECT EXISTS (SELECT * FROM `$guildID` WHERE user_id = $userID)");
    int result = queryExistance.first.values[0];
    if (result == 0) {
      //Row does not exist
      await connection.query("INSERT INTO `$guildID` SET "
          "user_id = $userID, "
          "total_cookies = $numCookies, "
          "available_cookies = $numCookies");
    } else {
      //Row exists
      await connection.query("UPDATE `$guildID` SET "
          "total_cookies = total_cookies + $numCookies, "
          "available_cookies = available_cookies + $numCookies "
          "WHERE user_id = $userID");
    }
    await connection.close();
  }

  Future<void> remove_cookies(int userID, int numCookies, int guildID) async {
    var connection = await dbConnect(user_config);
    var queryExistance = await connection.query(
        "SELECT EXISTS (SELECT * FROM `$guildID` WHERE user_id = $userID)");
    int result = queryExistance.first.values[0];
    if (result != 0) {
      await connection.query("UPDATE `$guildID` SET "
          "available_cookies = available_cookies - $numCookies "
          "WHERE user_id = $userID");
    }
    await connection.close();
  }

  Future<int> get_cookies(int userID, int guildID) async {
    var connection = await dbConnect(user_config);
    var queryExistance = await connection.query(
        "SELECT EXISTS (SELECT * FROM `$guildID` WHERE user_id = $userID)");
    int result = queryExistance.first.values[0];
    if (result != 0) {
      var row = await connection.query(
          "SELECT available_cookies FROM `$guildID` WHERE user_id = $userID");
      var numCookies = row.first.values[0];
      await connection.close();
      return numCookies;
    }
    await connection.close();
    return 0;
  }

  Future<void> increase_level(int userID, int numCookies, int guildID) async {}

  Future<void> create_table(int guildID) async {
    var connection = await dbConnect(user_config);
    await connection.query("CREATE TABLE IF NOT EXISTS `$guildID` ("
        "user_id BIGINT UNSIGNED PRIMARY KEY, "
        "total_cookies MEDIUMINT UNSIGNED, "
        "available_cookies MEDIUMINT UNSIGNED, "
        "level SMALLINT)");
    await connection.close();
  }

  Future<Iterator> get_rows(int guildID, String orderBy) async {
    //orderBy has to be a column in the database so:
    //user_id, available_cookies, total_cookies, or level
    //The limit will have to be removed if/when I learn pagnation
    //Unless i just show top 15
    var connection = await dbConnect(user_config);
    var rows = await connection.query("SELECT * FROM `$guildID` "
        "ORDER BY $orderBy DESC LIMIT 15");
    await connection.close();
    return rows.iterator;
  }
} 
