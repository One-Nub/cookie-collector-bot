part of commands;

class Leaderboard {
  final backArrow = UnicodeEmoji("⬅️");
  final forwardArrow = UnicodeEmoji("➡️");
  final trash = UnicodeEmoji("🗑");

  static const int maxRowsPerPage = 10;
  Map<int, String> pages = {};
  final Duration promptTimeout = Duration(seconds: 60);

  CCDatabase _database;

  Leaderboard(this._database);

  static bool preRunChecks(CommandContext ctx) {
    if (ctx.guild == null) {
      return false;
    }
    return true;
  }

  Future<void> commandFunction(CommandContext ctx, String message) async {
    String pageLeaderboard =
      await _getPageString(ctx.client, ctx.guild!.id.id, pageMax: maxRowsPerPage);

    var dbConnection = await _database.dbConnection();
    var query = await dbConnection.query("SELECT COUNT(*) FROM `${ctx.guild!.id.id}`");
    await dbConnection.close();

    int numRows = query.first.values[0];
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
      ..iconUrl = ctx.author!.avatarURL(format: "png");
    embed.footer = embedFooter;

    var leaderboardMessage = await ctx.channel.send(embed: embed);

    paginationHandler(ctx, leaderboardMessage, embed, pageMax);
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
          event.userId == ctx.author!.id;
    });
    reactionStream = reactionStream.timeout(promptTimeout, onTimeout: (sink) async {
        lbMessage.edit(content: "Prompt terminated.");
        lbMessage.deleteAllReactions();
        sink.close();
    });

    StreamSubscription<MessageReactionEvent>? reactionListener = null;
    reactionListener = await reactionStream.listen((event) async {
      var userReaction = event.emoji as UnicodeEmoji;
      if(userReaction == trash) {
        await lbMessage.edit(content: "Prompt terminated.");
        await lbMessage.deleteAllReactions();
        await reactionListener!.cancel();
      }
      else if(userReaction == forwardArrow) {
        if(maxPages - 1 > currentPageIndex) {
          currentPageIndex++;
          String description = await _getPageString(ctx.client, ctx.guild!.id.id,
            pageNumber: currentPageIndex, pageMax: maxRowsPerPage);
          lbEmbed.description = description;
          lbEmbed.footer = lbEmbed.footer!
            ..text = "Page ${currentPageIndex + 1} / $maxPages";
          lbMessage.edit(embed: lbEmbed);
          lbMessage.deleteUserReaction(userReaction, ctx.author!.id.toString());
        }
      }
      else if(userReaction == backArrow) {
        if(currentPageIndex > 0) {
          currentPageIndex--;
          String description = await _getPageString(ctx.client, ctx.guild!.id.id,
            pageNumber: currentPageIndex, pageMax: maxRowsPerPage);
          lbEmbed.description = description;
          lbEmbed.footer = lbEmbed.footer!
            ..text = "Page ${currentPageIndex + 1} / $maxPages";
          lbMessage.edit(embed: lbEmbed);
          lbMessage.deleteUserReaction(userReaction, ctx.author!.id.toString());
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
        Row row = pageIterator.current;
        Map<String, dynamic> rowInfo = row.fields;
        User? user = await client.getUser(Snowflake(rowInfo["user_id"]));
        output += "**${rowInfo["row_num"]}.** ${user!.tag} - `${rowInfo["available_cookies"]}`\n";
      }
      pages[pageNumber] = output;
      return output;
    }
}
