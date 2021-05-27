part of commands;

class Leaderboard extends Cooldown {
  final backArrow = UnicodeEmoji("⬅");
  final forwardArrow = UnicodeEmoji("➡️");
  final trash = UnicodeEmoji("🗑");

  static const int maxRowsPerPage = 10;
  Map<int, String> pages = {};
  final Duration promptTimeout = Duration(seconds: 60);

  late AllowedMentions _mentions;
  CCDatabase _database;

  Leaderboard(this._database) : super(Duration(seconds: 60)) {
    _mentions = AllowedMentions()..allow(reply: false, everyone: false);
  }

  Future<bool> preRunChecks(CommandContext ctx) async {
    if (ctx.guild == null) {
      return false;
    }

    if(super.isCooldownActive(ctx.guild!.id, ctx.author.id)) {
      String timeRemaining = super.getRemainingTime(ctx.guild!.id, ctx.author.id);
      EmbedBuilder errorEmbed = EmbedBuilder()
        ..color = DiscordColor.fromHexString("6B0504")
        ..description = "You're being restricted. Try again in `$timeRemaining`";
      await ctx.reply(MessageBuilder.embed(errorEmbed)
        ..allowedMentions = (AllowedMentions()..allow(users: false, reply: false)));
      return false;
    }

    return true;
  }

  Future<void> commandFunction(CommandContext ctx, String message) async {
    pages.clear();
    String pageLeaderboard =
      await _getPageString(ctx.client, ctx.guild!.id.id, pageMax: maxRowsPerPage);

    var dbConnection = await _database.dbConnection();
    var query = await dbConnection.query("SELECT COUNT(*) FROM users_guilds "
      "WHERE guild_id = ${ctx.guild!.id.id}");
    await dbConnection.close();

    int numRows = query.first.first! as int;
    int pageMax = (numRows / maxRowsPerPage <= 1) ?
      1 : (numRows / maxRowsPerPage).ceil();

    var embed = EmbedBuilder()
      ..color = DiscordColor.fromHexString("87CEEB")
      ..description = pageLeaderboard
      ..thumbnailUrl = ctx.guild!.iconURL(format: "png")
      ..timestamp = DateTime.now().toUtc()
      ..title = "Leaderboard";

    var embedFooter = EmbedFooterBuilder()
      ..text = "Page 1 / $pageMax"
      ..iconUrl = ctx.author.avatarURL(format: "png");
    embed.footer = embedFooter;

    var leaderboardMessage = await ctx.reply(MessageBuilder.embed(embed)
      ..allowedMentions = _mentions);
    if(pageMax > 1) {
      paginationHandler(ctx, leaderboardMessage, embed, pageMax);
    }

    super.applyCooldown(ctx.guild!.id, ctx.author.id);
  }

  Future<void> paginationHandler(CommandContext ctx, Message lbMessage,
  EmbedBuilder lbEmbed, int maxPages) async {
    //Help against rate limiting by delaying time it takes to add emojis.
    final delay = Duration(milliseconds: 250);
    await Future.delayed(delay, () =>
      lbMessage.createReaction(backArrow));
    await Future.delayed(delay, () =>
      lbMessage.createReaction(trash));
    await Future.delayed(delay, () =>
      lbMessage.createReaction(forwardArrow));

    int currentPageIndex = 0;
    var reactionStream = ctx.client.onMessageReactionAdded;
    reactionStream = reactionStream.where((event) {
        return event.messageId == lbMessage.id &&
          event.user.id == ctx.author.id;
    });
    reactionStream = reactionStream.timeout(promptTimeout, onTimeout: (sink) async {
        lbMessage.edit(MessageBuilder.content("Prompt terminated.")
          ..allowedMentions = _mentions);
        lbMessage.deleteAllReactions();
        sink.close();
    });

    StreamSubscription<MessageReactionEvent>? reactionListener = null;
    reactionListener = await reactionStream.listen((event) async {
      var userReaction = event.emoji as UnicodeEmoji;
      if(userReaction.encodeForAPI() == trash.encodeForAPI()) {
        await lbMessage.edit(MessageBuilder.content("Prompt terminated.")
          ..allowedMentions = _mentions);
        await lbMessage.deleteAllReactions();
        await reactionListener!.cancel();
      }
      else if(userReaction.encodeForAPI() == forwardArrow.encodeForAPI()) {
        if(maxPages - 1 > currentPageIndex) {
          currentPageIndex++;
          String description = await _getPageString(ctx.client, ctx.guild!.id.id,
            pageNumber: currentPageIndex, pageMax: maxRowsPerPage);
          lbEmbed.description = description;
          lbEmbed.footer = lbEmbed.footer!
            ..text = "Page ${currentPageIndex + 1} / $maxPages";
          lbMessage.edit(MessageBuilder.embed(lbEmbed)
            ..allowedMentions = _mentions);
          lbMessage.deleteUserReaction(userReaction, ctx.author);
        }
      }
      else if(userReaction.encodeForAPI() == backArrow.encodeForAPI()) {
        if(currentPageIndex > 0) {
          currentPageIndex--;
          String description = await _getPageString(ctx.client, ctx.guild!.id.id,
            pageNumber: currentPageIndex, pageMax: maxRowsPerPage);
          lbEmbed.description = description;
          lbEmbed.footer = lbEmbed.footer!
            ..text = "Page ${currentPageIndex + 1} / $maxPages";
          lbMessage.edit(MessageBuilder.embed(lbEmbed)
            ..allowedMentions = _mentions);
          lbMessage.deleteUserReaction(userReaction, ctx.author);
        }
      }
    });
  }

  Future<String> _getPageString(Nyxx client, int guildID, {int pageNumber = 0,
    int pageMax = maxRowsPerPage}) async {
      if(pages.containsKey(pageNumber)) {
        return pages[pageNumber]!;
      }

      String output = "";
      var pageIterator = await _database.leaderboardSelection(guildID,
        pageNumber: pageNumber, pageEntryMax: pageMax);

      while (pageIterator.moveNext()) {
        ResultRow row = pageIterator.current;
        Map<String, dynamic> rowInfo = row.fields;

        // Get users from cache (and if they're not in cache get from upstream then cache)
        User? user = client.users[Snowflake(rowInfo["user_id"])];
        user ??= await client.fetchUser(Snowflake(rowInfo["user_id"]));
        client.users.addIfAbsent(Snowflake(rowInfo["user_id"]), user);

        output += "**${rowInfo["row_num"]}.** ${user.tag} - `${rowInfo["cookies"]}`\n";
      }
      pages[pageNumber] = output;
      return output;
    }
}
