part of framework;

mixin Cooldown {
  static Duration cooldownDuration = Duration(seconds: 5);
  static HashMap<Snowflake, HashMap<Snowflake, DateTime>> _cooldownCache = new HashMap();
  
  static void applyCooldown(Snowflake guildID, Snowflake userSnowflake) {
    DateTime offsetDuration = DateTime.now().add(cooldownDuration);
    _cooldownCache[guildID] ??= new HashMap();

    _cooldownCache[guildID]![userSnowflake] = offsetDuration;
  }

  ///True if the user is currently on cooldown, false otherwise.
  static bool isCooldownActive(Snowflake guildID, Snowflake userSnowflake) {
    if(!_cooldownCache.containsKey(guildID)) return false;
    if(!_cooldownCache[guildID]!.containsKey(userSnowflake)) return false;

    return _cooldownCache[guildID]![userSnowflake]!.isAfter(DateTime.now());
  }

  static DateTime? getCooldownTime(Snowflake guildID, Snowflake userSnowflake) {
    return _cooldownCache[guildID]?[userSnowflake];
  }

  static String getRemainingTime(Snowflake guildID, Snowflake userSnowflake) {
    if(_cooldownCache.containsKey(guildID) && _cooldownCache[guildID]!.containsKey(userSnowflake)) {
      return DateTimeFormat.relative(_cooldownCache[guildID]![userSnowflake], 
        round: false, levelOfPrecision: 5, excludeWeeks: true);
    }
    return "Cooldown is not applied.";
  }
}