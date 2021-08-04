part of commands;

class Daily extends Cooldown {
  static const int baseReward = 15;
  static const int rewardIncInterval = 5;
  CCDatabase _database;
  late AllowedMentions _allowedMentions;

  ///Snowflake: Guild ID
  ///Guild Users Map:
  /// Snowflake: User ID
  /// User Info Map:
  ///   streak: Streak length
  ///   time: DateTime when streak expires (2 days from now)
  Map<Snowflake, Map<Snowflake, Map<String, dynamic>>> _streakTracker = {};

  Daily(this._database) : super(Duration(hours: 24)) {
    _allowedMentions = AllowedMentions();
    _allowedMentions.allow(users: false, reply: false);
  }

  Future<bool> preRunChecks(CommandContext ctx) async {
    if(ctx.guild == null) {
      return false;
    }

    if(super.isCooldownActive(ctx.guild!.id, ctx.author.id)) {
      String timeRemaining = super.getRemainingTime(ctx.guild!.id, ctx.author.id);
      EmbedBuilder errorEmbed = EmbedBuilder()
        ..color = DiscordColor.fromHexString("6B0504")
        ..description = "It hasn't been a full day yet! Try again in `$timeRemaining`"
        ..addAuthor((author) {
          author.name = ctx.author.tag;
          author.iconUrl = ctx.author.avatarURL(format: "png");
        });
      await ctx.reply(MessageBuilder.embed(errorEmbed)..allowedMentions = _allowedMentions);
      return false;
    }
    return true;
  }

  Future<void> commandFunction(CommandContext ctx, String msg) async {
    int streakDuration = _getStreakDuration(ctx.guild!.id, ctx.author.id);
    //If streak is less than 30 days, divide the duration by reward interval
    //taking the lowest number and multiply by 2. Otherwise just use 30 as duration.
    int streakRewardModifier = (streakDuration < 30) ?
      (streakDuration / rewardIncInterval).floor() * 2 :
      (30 / rewardIncInterval).floor() * 2;

    int reward = baseReward + streakRewardModifier;
    await _database.addCookies(ctx.author.id.id, reward, ctx.guild!.id.id);
    await _database.addLifetimeCookies(ctx.author.id.id, reward, ctx.guild!.id.id);

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

    await ctx.reply(MessageBuilder.embed(replyEmbed)..allowedMentions = _allowedMentions);
    super.applyCooldown(ctx.guild!.id, ctx.author.id);
  }

  int _getStreakDuration(Snowflake guildID, Snowflake userID) {
    //Create empty map for guild for streak tracking
    if(!_streakTracker.containsKey(guildID)) {
      _streakTracker[guildID] = {};
    }

    var userStreakMap = _streakTracker[guildID];
    if(userStreakMap!.containsKey(userID)) {
      var userStreakInfo = userStreakMap[userID]!;
      //Increments streak if user is collecting before streak expires
      if(DateTime.now().isBefore(userStreakInfo["time"] as DateTime)) {
        userStreakInfo["streak"] += 1;
      } else {
        userStreakInfo["streak"] = 1;
      }
      userStreakInfo["time"] = DateTime.now().add(Duration(days: 2));
    }
    else {
      //Create streak for user
      userStreakMap[userID] = {
        "streak" : 1,
        "time" : DateTime.now().add(Duration(days: 2))
      };
    }
    return userStreakMap[userID]!["streak"];
  }
}