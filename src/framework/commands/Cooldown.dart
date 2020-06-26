part of framework;

mixin Cooldown {
  static Duration cooldownDuration = Duration(seconds: 5);
  static HashMap<Snowflake, DateTime> _cooldownCache = new HashMap();
  
  static void applyCooldown(Snowflake userSnowflake) {
    DateTime offsetDuration = DateTime.now().add(cooldownDuration);
    _cooldownCache[userSnowflake] = offsetDuration;
  }

  ///True if the user is currently on cooldown, false otherwise.
  static bool isCooldownActive(Snowflake userSnowflake) {
    if(!_cooldownCache.containsKey(userSnowflake)) return false;

    return _cooldownCache[userSnowflake]!.isAfter(DateTime.now());
  }

  static DateTime? getCooldownTime(Snowflake userSnowflake) {
    return _cooldownCache[userSnowflake];
  }

  static String getRemainingTime(Snowflake userSnowflake) {
    if(_cooldownCache.containsKey(userSnowflake)) {
      return DateTimeFormat.relative(_cooldownCache[userSnowflake], 
        minUnitOfTime: UnitOfTime.millisecond);
    }
    return "Cooldown is not applied.";
  }
}