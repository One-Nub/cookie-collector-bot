part of framework;

class CCBot extends Nyxx {

  late List<Snowflake> admins = [];
  HashSet<GuildListener> guildListeners = HashSet();

  CCBot(String token, int intents,
      {ClientOptions? options, CacheOptions? cacheOptions,
      bool ignoreExceptions = true, bool useDefaultLogger = true,
      Level? defaultLoggerLogLevel,
      admins}) : 
        super(token, intents, options: options, cacheOptions: cacheOptions,
              ignoreExceptions: ignoreExceptions, useDefaultLogger: useDefaultLogger,
              defaultLoggerLogLevel: defaultLoggerLogLevel);

  bool addGuildListener(GuildListener gl) => guildListeners.add(gl);
  bool removeGuildListener(GuildListener gl) => guildListeners.remove(gl);
}