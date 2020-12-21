part of framework;

/// Enables different classes with different heirarchies to potentially implement
/// a cooldown.
mixin Cooldown {
  static Duration cooldownDuration = Duration(seconds: 5);
  
  /// Guild ID, Map<User ID, End time>
  static HashMap<Snowflake, HashMap<Snowflake, DateTime>> _cooldownCache = new HashMap();
  
  /// Adds a user to the cooldown
  static void applyCooldown(Snowflake guildID, Snowflake userSnowflake) {
    DateTime offsetDuration = DateTime.now().add(cooldownDuration);
    _cooldownCache[guildID] ??= new HashMap();

    _cooldownCache[guildID]![userSnowflake] = offsetDuration;
  }

  /// True if the user is currently on cooldown, false otherwise.
  static bool isCooldownActive(Snowflake guildID, Snowflake userSnowflake) {
    if(!_cooldownCache.containsKey(guildID)) return false;
    if(!_cooldownCache[guildID]!.containsKey(userSnowflake)) return false;

    return _cooldownCache[guildID]![userSnowflake]!.isAfter(DateTime.now());
  }

  /// Returns the time the cooldown expires
  static DateTime? getCooldownTime(Snowflake guildID, Snowflake userSnowflake) {
    return _cooldownCache[guildID]?[userSnowflake];
  }

  /// Returns the amount of time remaining
  static String getRemainingTime(Snowflake guildID, Snowflake userSnowflake) {
    if(_cooldownCache.containsKey(guildID) && _cooldownCache[guildID]!.containsKey(userSnowflake)) {
      return DateTimeFormat.relative(_cooldownCache[guildID]![userSnowflake]!, 
        round: false, levelOfPrecision: 5, excludeWeeks: true);
    }
    return "Cooldown is not applied.";
  }
}