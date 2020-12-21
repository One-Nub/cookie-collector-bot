part of commands;

class Daily with Cooldown {
  static const int baseReward = 15;
  static const int rewardIncInterval = 5;
  CCDatabase _database;

  ///Snowflake: Guild ID
  ///Guild Users Map:
  /// Snowflake: User ID
  /// User Info Map:
  ///   streak: Streak length
  ///   time: DateTime when streak expires (2 days from now)
  Map<Snowflake, Map<Snowflake, Map<String, dynamic>>> _streakTracker = {};

  Daily(this._database) {
    Cooldown.cooldownDuration = Duration(hours: 24);
  }

  static Future<bool> preRunChecks(CommandContext ctx) async {
    if(ctx.guild == null) {
      return false;
    }

    if(Cooldown.isCooldownActive(ctx.guild!.id, ctx.author.id)) {
      String timeRemaining = Cooldown.getRemainingTime(ctx.guild!.id, ctx.author.id);
      EmbedBuilder errorEmbed = EmbedBuilder()
        ..color = DiscordColor.fromHexString("6B0504")
        ..description = "It hasn't been a full day yet! Try again in `$timeRemaining`"
        ..addAuthor((author) {
          author.name = ctx.author.tag;
          author.iconUrl = ctx.author.avatarURL(format: "png");
        });
      await ctx.reply(embed: errorEmbed);
      return false;
    }
    return true;
  }

  Future<void> commandFunction(CommandContext ctx, String msg) async {
    int streakDuration = _getStreakDuration(ctx.guild!.id, ctx.author.id);
    int streakRewardModifier = (streakDuration < 30) ?
      (streakDuration / rewardIncInterval).floor() * 2 :
      (30 / rewardIncInterval).floor() * 2;

    int reward = baseReward + streakRewardModifier;
    await _database.addCookies(ctx.author.id.id, reward, ctx.guild!.id.id);

    EmbedBuilder replyEmbed = EmbedBuilder()
      ..description = "You have collected your daily `$reward` cookies! \n"
        "You are now on a streak of `$streakDuration` day${(streakDuration != 1) ? "s" : ""}."
      ..timestamp = DateTime.now().toUtc().add(Duration(days: 1))
      ..color = DiscordColor.fromHexString("67F399");
    replyEmbed.addAuthor((author) {
      author.name = "Daily Cookies - ${ctx.author.tag}";
      author.iconUrl = ctx.author.avatarURL(format: "png");
    });
    replyEmbed.addFooter((footer) {
      footer.text = "You can collect again in 24 hours.";
    });

    await ctx.reply(embed: replyEmbed);
    Cooldown.applyCooldown(ctx.guild!.id, ctx.author.id);
  }

  int _getStreakDuration(Snowflake guildID, Snowflake userID) {
    if(!_streakTracker.containsKey(guildID)) {
      _streakTracker[guildID] = {};
    }

    var userStreakMap = _streakTracker[guildID];
    if(userStreakMap!.containsKey(userID)) {
      var userStreakInfo = userStreakMap[userID]!;
      if(DateTime.now().isBefore(userStreakInfo["time"] as DateTime)) {
        userStreakInfo["streak"] += 1;
      } else {
        userStreakInfo["streak"] = 1;
      }
      userStreakInfo["time"] = DateTime.now().add(Duration(days: 2));
    }
    else {
      userStreakMap[userID] = {
        "streak" : 1,
        "time" : DateTime.now().add(Duration(days: 2))
      };
    }
    return userStreakMap[userID]!["streak"];
  }
}
