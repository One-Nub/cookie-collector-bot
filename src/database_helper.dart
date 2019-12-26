import 'package:mysql1/mysql1.dart';

class database_helper {
  var connection;

  Future<void> connect(String username, String password, String host,
      String database, int port) async {
    var user_config = new ConnectionSettings(
        user: username,
        password: password,
        host: host,
        db: database,
        port: port);
    connection = await MySqlConnection.connect(user_config);
  }

  Future<void> add_cookies(int userID, int numCookies, int guildID) async {
    //No user input is ever used here so sanitization isn't as concerning, though
    //typically good in practice
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
  }

  Future<void> remove_cookies(int userID, int numCookies, int guildID) async {
    var queryExistance = await connection.query(
        "SELECT EXISTS (SELECT * FROM `$guildID` WHERE user_id = $userID)");
    int result = queryExistance.first.values[0];
    if (result != 0) {
      await connection.query("UPDATE `$guildID` SET "
        "available_cookies = available_cookies - $numCookies "
        "WHERE user_id = $userID");
    }
  }

  Future<int> get_cookies(int userID, int guildID) async {
    var queryExistance = await connection.query(
        "SELECT EXISTS (SELECT * FROM `$guildID` WHERE user_id = $userID)");
    int result = queryExistance.first.values[0];
    if (result != 0) {
      var row = await connection.query(
          "SELECT available_cookies FROM `$guildID` WHERE user_id = $userID");
      var numCookies = row.first.values[0];
      return numCookies;
    }
    return 0;
  }

  Future<void> increase_level(int userID, int numCookies, int guildID) async {}

  Future<void> create_table(int guildID) async {
    connection.query("CREATE TABLE IF NOT EXISTS `$guildID` ("
        "user_id BIGINT UNSIGNED PRIMARY KEY, "
        "total_cookies MEDIUMINT UNSIGNED, "
        "available_cookies MEDIUMINT UNSIGNED, "
        "level SMALLINT)");
  }

  Future<Iterator> get_rows(int guildID, String orderBy) async {
    //orderBy has to be a column in the database so: 
    //user_id, available_cookies, total_cookies, or level
    //The limit will have to be removed if/when I learn pagnation
    //Unless i just show top 15
    var rows = await connection.query("SELECT * FROM `$guildID` "
    "ORDER BY $orderBy DESC LIMIT 15");
    return rows.iterator;
  }
}
