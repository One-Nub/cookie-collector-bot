import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';

class CCDatabase {
  late final ConnectionSettings _connectionSettings;
  final String _username;
  final String _password;
  final String _host;
  final String _databaseName;
  final int _port;

  CCDatabase(this._username, this._password, this._host, this._databaseName, this._port) {
    this._connectionSettings = ConnectionSettings(
      user: _username,
      password: _password,
      host: _host,
      db: _databaseName,
      port: _port);
  }

  Future<MySqlConnection> dbConnection() async {
    //TODO: Consider a different solution than exiting on error
    try {
      return await MySqlConnection.connect(_connectionSettings);
    }
    on TimeoutException catch (e) {
      Logger("CCDB")
        .severe("It took too long to connect to the database.\n" +
      "Because of this the program will now exit for integrity.\n$e");
      exit(1);
    }
    on SocketException catch (e) {
      Logger("CCDB")
        .severe("An issue was enountered with the credentials given.\n" +
      "Because of this the program will now exit for integrity. \n$e");
      exit(1);
    }
  }

  Future<void> createGuildTable(int guildID) async {
    var connection = await dbConnection();
    await connection.query("CREATE TABLE IF NOT EXISTS `$guildID` ("
        "user_id BIGINT UNSIGNED PRIMARY KEY, "
        "available_cookies INT DEFAULT 0, "
        "level SMALLINT DEFAULT 0)");
    await connection.close();
  }

  Future<Iterator> getRowRange(int guildID, String orderBy, 
    {int startIndex = 0, int rowCount = 15}) async {
    
    var connection = await dbConnection();
    String query = "SELECT * FROM `$guildID`" 
      "ORDER BY $orderBy DESC "
      "LIMIT $startIndex,$rowCount";

    var rows = await connection.query(query.toString());
    await connection.close();
    return rows.iterator;
  }

  Future<Row?> getStoredUser(int userID, int guildID) async {
    Row? returnRow = null;
    var connection = await dbConnection();
    var results = await connection.query("SELECT * FROM `$guildID` "
        "WHERE user_id = $userID");
    if(results.isNotEmpty) {
      returnRow = results.first;
    }
    await connection.close();
    return returnRow;
  }



  Future<void> addCookies(int userID, int numCookies, int guildID) async {
    var connection = await dbConnection();
    String query = "INSERT INTO `$guildID` (user_id, available_cookies) "
      "VALUES ($userID, $numCookies) "
      "ON DUPLICATE KEY UPDATE"
      "available_cookies = available_cookies + $numCookies";
    await connection.query(query);
    await connection.close();
  }

  Future<void> removeCookies(int userID, int numCookies, int guildID) async {
    var connection = await dbConnection();
    String query = "INSERT INTO `$guildID` (user_id, available_cookies) "
      "VALUES ($userID, -$numCookies) "
      "ON DUPLICATE KEY UPDATE"
      "available_cookies = available_cookies - $numCookies";
    await connection.query(query);
    await connection.close();
  }

  Future<int> getCookieCount(int userID, int guildID) async {
    var connection = await dbConnection();
    var numCookies = 0;
    String query = "SELECT available_cookies FROM `$guildID` WHERE user_id = $userID";
    var row = await connection.query(query);
    if(row.isNotEmpty) {
      numCookies = row.first.fields["available_cookies"];
    }
    await connection.close();
    return numCookies;
  }

  Future<void> increaseLevel(int userID, int numCookies, int guildID) async {}
}
