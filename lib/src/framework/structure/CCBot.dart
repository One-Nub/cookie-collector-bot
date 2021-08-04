part of framework;

class CCBot extends Nyxx {

  late List<Snowflake> admins = [];
  HashMap<Snowflake, GuildListener> guildListeners = HashMap();

  CCBot(String token, int intents,
      {ClientOptions? options, CacheOptions? cacheOptions,
      bool ignoreExceptions = true, bool useDefaultLogger = true,
      Level? defaultLoggerLogLevel,
      admins}) :
        super(token, intents, options: options, cacheOptions: cacheOptions,
              ignoreExceptions: ignoreExceptions, useDefaultLogger: useDefaultLogger,
              defaultLoggerLogLevel: defaultLoggerLogLevel);

  bool checkForGuildListener(Snowflake guildID) {
    return guildListeners.containsKey(guildID);
  }

  void addGuildListener(Snowflake guildID, GuildListener gl) {
    guildListeners.putIfAbsent(guildID, () => gl);
  }

  void removeGuildListener(Snowflake guildID, GuildListener gl) {
    guildListeners.removeWhere((key, value) => key == guildID);
  }
}
