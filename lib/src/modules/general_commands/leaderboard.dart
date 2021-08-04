import 'package:mysql1/mysql1.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commander/commander.dart';
import 'package:nyxx_interactions/interactions.dart';

import '../../core/CCDatabase.dart';
import '../../framework/commands/Cooldown.dart';

class Leaderboard extends Cooldown {
  static const int maxRowsPerPage = 10;
  Map<int, String> pages = {};
  final Duration promptTimeout = Duration(seconds: 60);
  final Interactions _interactions;

  late AllowedMentions _mentions;
  CCDatabase _database;

  Leaderboard(this._database, this._interactions) : super(Duration(seconds: 60)) {
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
        ..allowedMentions = _mentions);
      return false;
    }

    return true;
  }

  Future<void> commandFunction(CommandContext ctx, String message) async {
    pages.clear();
    String pageLeaderboard =
      await _getPageString(ctx.client, ctx.guild!.id.id);

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

    ComponentMessageBuilder leaderboardMessageBuilder = ComponentMessageBuilder()
      ..embeds = [embed]
      ..allowedMentions = _mentions;

    if(pageMax > 1) {
      int sourceMessageID = ctx.message.id.id;
      ButtonBuilder previousButton = ButtonBuilder("Previous", "lb_prev_$sourceMessageID",
        ComponentStyle.primary,
        disabled: true);
      ButtonBuilder nextButton = ButtonBuilder("Next", "lb_next_$sourceMessageID",
        ComponentStyle.primary);
      ButtonBuilder deleteButton = ButtonBuilder(" ", "lb_delete_$sourceMessageID",
        ComponentStyle.danger,
        emoji: UnicodeEmoji("🗑"));

      List<IComponentBuilder> buttonList = [previousButton, nextButton, deleteButton];
      leaderboardMessageBuilder.addButtonRow(buttonList);
      Message leaderboardMessage = await ctx.reply(leaderboardMessageBuilder);

      paginationHandler(ctx, leaderboardMessage, embed, pageMax, buttonList);
    }
    else {
      await ctx.reply(leaderboardMessageBuilder);
    }

    super.applyCooldown(ctx.guild!.id, ctx.author.id);
  }

  Future<void> paginationHandler(CommandContext ctx, Message lbMessage,
  EmbedBuilder lbEmbed, int maxPages, List<IComponentBuilder> buttonList) async {
    int currentPageIndex = 0;

    var buttonStream = _interactions.onButtonEvent;
    buttonStream = buttonStream.where((event) {
      int sourceMessageID = ctx.message.id.id;

      return (event.interaction.metadata == "lb_prev_$sourceMessageID" ||
        event.interaction.metadata == "lb_next_$sourceMessageID" ||
        event.interaction.metadata == "lb_delete_$sourceMessageID") &&
        event.interaction.memberAuthor.id == ctx.author.id;
    });
    buttonStream = buttonStream.timeout(promptTimeout, onTimeout: (sink) {
      lbMessage.edit(ComponentMessageBuilder()
        ..content = "Prompt timed out."
        ..buttons = []);
      sink.close();
      return;
    });

    await for (ComponentInteractionEvent buttonEvent in buttonStream) {
      //Remove the added message ID on the end.
      String metadata = buttonEvent.interaction.metadata.replaceAll(RegExp(r"_\d+"), "");

      if(metadata == "lb_prev") {
        currentPageIndex--;
      }
      else if(metadata == "lb_next") {
        currentPageIndex++;
      }
      else if(metadata == "lb_delete") {
        lbMessage.edit(ComponentMessageBuilder()
        ..content = "Prompt terminated."
        ..buttons = []);
        return;
      }

      // Prevent page count above max pages.
      if(currentPageIndex > maxPages - 1) {
        currentPageIndex = maxPages - 1;
      }

      // Prevent negative page count
      if(currentPageIndex < 0) {
        currentPageIndex = 0;
      }

      if(currentPageIndex == 0) {
        buttonList[0].disabled = true;
        buttonList[1].disabled = false;
      }
      else if(currentPageIndex == maxPages - 1) {
        buttonList[0].disabled = false;
        buttonList[1].disabled = true;
      }
      else {
        buttonList.forEach((element) {element.disabled = false;});
      }

      lbEmbed.description = await _getPageString(ctx.client, ctx.guild!.id.id,
        pageIndex: currentPageIndex);
      lbEmbed.footer = lbEmbed.footer!
        ..text = "Page ${currentPageIndex + 1} / $maxPages";

      lbMessage.edit(ComponentMessageBuilder()
        ..embeds = [lbEmbed]
        ..buttons = [buttonList]);
      buttonEvent.acknowledge();
    }
  }

  Future<String> _getPageString(Nyxx client, int guildID, {int pageIndex = 0,
    int pageMaxRows = maxRowsPerPage}) async {
      if(pages.containsKey(pageIndex)) {
        return pages[pageIndex]!;
      }

      String output = "";
      var pageIterator = await _database.leaderboardSelection(guildID,
        pageNumber: pageIndex, pageEntryMax: pageMaxRows);

      while (pageIterator.moveNext()) {
        ResultRow row = pageIterator.current;
        Map<String, dynamic> rowInfo = row.fields;

        // Get users from cache (and if they're not in cache get from upstream then cache)
        User? user = client.users[Snowflake(rowInfo["user_id"])];
        user ??= await client.fetchUser(Snowflake(rowInfo["user_id"]));
        client.users.addIfAbsent(Snowflake(rowInfo["user_id"]), user);

        output += "**${rowInfo["row_num"]}.** ${user.tag} - `${rowInfo["cookies"]}`\n";
      }
      pages[pageIndex] = output;
      return output;
    }
}
