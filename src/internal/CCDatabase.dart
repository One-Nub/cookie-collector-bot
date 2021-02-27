import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';

class CCDatabase {
  late final ConnectionSettings _connectionSettings;

  CCDatabase(String _username, String _password, String _host, String _databaseName, int _port) {
    this._connectionSettings = ConnectionSettings(
      user: _username,
      password: _password,
      host: _host,
      db: _databaseName,
      port: _port);
  }

  ///Establishes a connection with the database.
  ///Throws when it can't connect to the database & stops program.
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
        .severe("An issue was enountered with the Socket connection.\n" +
      "Because of this the program will now exit for integrity. \n$e");
      exit(1);
    }
  }

//------------------------- Database Setup -------------------------\\

  ///Initializes the expected tables in the database if they don't exist.
  Future<void> initializeTables() async {
    var connection = await dbConnection();

    //Users table
    await connection.query("CREATE TABLE IF NOT EXISTS users ( "
      "id BIGINT NOT NULL PRIMARY KEY, "
      "partner BIGINT DEFAULT NULL, "
      "parent BIGINT DEFAULT NULL, "
      "bank_storage INT DEFAULT 0)");

    //Guilds table
    await connection.query("CREATE TABLE IF NOT EXISTS guilds ( "
      "id BIGINT NOT NULL PRIMARY KEY, "
      "prefix TINYTEXT DEFAULT '.', "
      "collect_channel_id BIGINT DEFAULT NULL)");

    //Junction table w/ Users & Guilds
    await connection.query("CREATE TABLE IF NOT EXISTS users_guilds ( "
      "user_id BIGINT NOT NULL, "
      "guild_id BIGINT NOT NULL, "
      "cookies INT DEFAULT 0, "
      "lifetime_cookies INT DEFAULT 0,"
      "CONSTRAINT `pk_users_guilds`  "
          "PRIMARY KEY (user_id, guild_id),"
      "CONSTRAINT `fk_user_id` "
          "FOREIGN KEY (user_id) REFERENCES users (id) "
          "ON DELETE CASCADE, "
      "CONSTRAINT `fk_guild_id` "
          "FOREIGN KEY (guild_id) REFERENCES guilds (id)"
          "ON DELETE CASCADE)");

    await connection.close();
  }

  ///Adds a guild to the guilds table
  Future<void> addGuildRow(int guildID) async {
    var connection = await dbConnection();
    //Updates nothing when it exists
    await connection.query("INSERT INTO guilds (id) VALUES ($guildID) "
      "ON DUPLICATE KEY UPDATE id=id");
    await connection.close();
  }

  //Adds a user to the users table
  Future<void> addUserRow(int userID) async {
    var con = await dbConnection();
    await con.query("INSERT INTO users (id) VALUES ($userID)"
      "ON DUPLICATE KEY UPDATE id=id");
    await con.close();
  }

  ///This probably won't be needed. Just making it for storage reasons currently
  Future<void> addUserGuildLink(int guildID, int userID) async {
    var con = await dbConnection();
    await con.query("INSERT INTO users_guilds (user_id, guild_id) VALUES ($userID, $guildID) "
      "ON DUPLICATE KEY UPDATE 0+0"); //When used elsewhere the dup key will probably be updating cookie count
    await con.close();
    //I'll need a way to affirm that the user already exists in the users table
    //I might just always call addGuildRow() and addUserRow() before adding/updating data in
    //the junction table since that will confirm it exists
  }

//------------------------- TBD -------------------------\\

  Future<Iterator> leaderboardSelection(int guildID, {int pageNumber = 0,
    int pageEntryMax = 15}) async {

    var connection = await dbConnection();
    String query = "SELECT * FROM ("
  	"SELECT ROW_NUMBER() OVER(ORDER BY cookies DESC) "
  	"AS row_num, user_id, cookies "
  	"FROM users_guilds WHERE (guild_id = $guildID) ORDER BY row_num) rnt "
    "WHERE rnt.row_num > ${pageNumber * pageEntryMax} LIMIT $pageEntryMax";

    var result = await connection.query(query);
    await connection.close();
    return result.iterator;
  }

  Future<Row?> getUserGuildData(int userID, int guildID) async {
    Row? returnRow = null;
    var connection = await dbConnection();
    var results = await connection.query("SELECT * FROM users_guilds "
        "WHERE (user_id = $userID AND guild_id = $guildID)");
    if(results.isNotEmpty) {
      returnRow = results.first;
    }
    await connection.close();
    return returnRow;
  }

  Future<Row?> getRankedUserGuildData(int userID, int guildID) async {
    Row? returnRow = null;
    var connection = await dbConnection();
    String query = "SELECT * FROM ("
      "SELECT ROW_NUMBER() OVER(ORDER BY cookies DESC) "
      "AS row_num, user_id, cookies "
      "FROM users_guilds WHERE (guild_id = $guildID) ORDER BY row_num) rnt "
      "WHERE user_id = $userID";
    var results = await connection.query(query);
    if(results.isNotEmpty) {
      returnRow = results.first;
    }
    await connection.close();
    return returnRow;
  }


  Future<void> addCookies(int userID, int numCookies, int guildID) async {
    await addGuildRow(guildID);
    await addUserRow(userID);
    var connection = await dbConnection();
    String query = "INSERT INTO users_guilds (user_id, guild_id, cookies) "
      "VALUES ($userID, $guildID, $numCookies)"
      "ON DUPLICATE KEY UPDATE cookies = cookies + $numCookies";
    await connection.query(query);
    await connection.close();
  }

  Future<void> removeCookies(int userID, int numCookies, int guildID) async {
    await addGuildRow(guildID);
    await addUserRow(userID);
    var connection = await dbConnection();
    String query = "INSERT INTO users_guilds (user_id, guild_id, cookies) "
      "VALUES ($userID, $guildID, -$numCookies)"
      "ON DUPLICATE KEY UPDATE cookies = cookies - $numCookies";
    await connection.query(query);
    await connection.close();
  }

  Future<void> addLifetimeCookies(int userID, int numCookies, int guildID) async {
    await addGuildRow(guildID);
    await addUserRow(userID);
    var connection = await dbConnection();
    String query = "INSERT INTO users_guilds (user_id, guild_id, lifetime_cookies) "
      "VALUES ($userID, $guildID, $numCookies)"
      "ON DUPLICATE KEY UPDATE lifetime_cookies = lifetime_cookies + $numCookies";
    await connection.query(query);
    await connection.close();
  }

  Future<void> removeLifetimeCookies(int userID, int numCookies, int guildID) async {
    await addGuildRow(guildID);
    await addUserRow(userID);
    var connection = await dbConnection();
    String query = "INSERT INTO users_guilds (user_id, guild_id, lifetime_cookies) "
      "VALUES ($userID, $guildID, -$numCookies)"
      "ON DUPLICATE KEY UPDATE lifetime_cookies = lifetime_cookies - $numCookies";
    await connection.query(query);
    await connection.close();
  }

  Future<int> getCookieCount(int userID, int guildID) async {
    var connection = await dbConnection();
    var numCookies = 0;
    String query = "SELECT cookies FROM users_guilds "
      "WHERE (user_id = $userID AND guild_id = $guildID)";
    var row = await connection.query(query);
    if(row.isNotEmpty) {
      numCookies = row.first.fields["cookies"];
    }
    await connection.close();
    return numCookies;
  }
}
