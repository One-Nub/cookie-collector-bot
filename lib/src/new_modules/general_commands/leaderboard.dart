import 'dart:collection';

import 'package:mysql_client/mysql_client.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCBot.dart';
import '../../core/CCDatabase.dart';

final Map<String, DateTime> lastCommandRun = Map();
final Duration cooldown = Duration(minutes: 1);
final Duration promptTimeout = Duration(seconds: 60);
final AllowedMentions _allowedMentions = AllowedMentions()..allow(reply: false, everyone: false);

class LeaderboardCommand extends TextCommand {
  static const int maxRowsPerPage = 10;
  final Map<int, String> pages = Map();

  // no footer, thumbnail URL, or description.
  final EmbedBuilder baseEmbed = EmbedBuilder()
    ..color = DiscordColor.fromHexString("87CEEB")
    ..timestamp = DateTime.now().toUtc()
    ..title = "Leaderboard";

  @override
  String get name => "leaderboard";

  @override
  HashSet<String> get aliases => HashSet.from(["lb"]);

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    int authorID = ctx.author.id.id;
    int guildID = ctx.guild!.id.id;
    String mapEntry = "$guildID-$authorID";

    if (lastCommandRun.containsKey(mapEntry)) {
      if (lastCommandRun[mapEntry]!.add(cooldown).isAfter(DateTime.now())) {
        EmbedBuilder errorEmbed = EmbedBuilder()
          ..color = DiscordColor.fromHexString("6B0504")
          ..description = "You're being restricted. Try again in little bit";
        await ctx.channel.sendMessage(MessageBuilder.embed(errorEmbed)
          ..allowedMentions = (AllowedMentions()..allow(reply: false))
          ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
        return;
      }
    }
    lastCommandRun[mapEntry] = DateTime.now();

    CCDatabase db = CCDatabase(initializing: false);
    var countQuery = await db.pool.execute("SELECT COUNT(*) FROM users_guilds WHERE guild_id = $guildID");
    var queryResultMap = countQuery.rows.first.typedAssoc();
    int rowCount = queryResultMap["COUNT(*)"];

    int maxPageCount = (rowCount / maxRowsPerPage <= 1) ? 1 : (rowCount / maxRowsPerPage).ceil();
    int pageIndex = 0;

    baseEmbed.description = await _generatePage(ctx);
    baseEmbed.thumbnailUrl = ctx.guild!.iconURL();
    baseEmbed.footer = EmbedFooterBuilder()
      ..text = "Page 1 / $maxPageCount"
      ..iconUrl = ctx.author.avatarURL();

    ComponentMessageBuilder cmb = ComponentMessageBuilder()
      ..embeds = [baseEmbed]
      ..allowedMentions = _allowedMentions
      ..replyBuilder = ReplyBuilder.fromMessage(ctx.message);

    if (maxPageCount == 1) {
      await ctx.channel.sendMessage(cmb);
      return;
    }

    cmb.componentRows = [
      ComponentRowBuilder()
        ..addComponent(ButtonBuilder("<", "lb_prev", ButtonStyle.primary, disabled: true))
        ..addComponent(ButtonBuilder(" ", "lb_delete", ButtonStyle.danger, emoji: UnicodeEmoji("🗑")))
        ..addComponent(ButtonBuilder(">", "lb_next", ButtonStyle.primary))
    ];

    var lbMessage = await ctx.channel.sendMessage(cmb);

    CCBot bot = CCBot();
    IInteractions interactions = bot.interactions;

    /// Recreate event stream with only events by the author on this message
    var lbBStream = interactions.events.onButtonEvent.where((event) {
      return event.interaction.memberAuthor!.id == ctx.author.id &&
          event.interaction.message!.id == lbMessage.id;
    });

    /// Reassign value to a stream that times out after a minute.
    lbBStream = lbBStream.timeout(promptTimeout, onTimeout: (sink) {
      lbMessage.edit(ComponentMessageBuilder()
        ..content = "Prompt timed out."
        ..componentRows = []
        ..allowedMentions = _allowedMentions);
      sink.close();
      return;
    });

    lbBStream.listen((event) async {
      String eventValue = event.interaction.customId;
      if (eventValue == "lb_prev") {
        /// If at min page, don't change
        pageIndex = (pageIndex - 1 < 0) ? pageIndex : pageIndex - 1;
        await _prevButtonHandler(ctx, maxPageCount, pageIndex, lbMessage);
      } else if (eventValue == "lb_next") {
        /// If over the max page count, don't change
        pageIndex = (pageIndex + 1 > maxPageCount) ? pageIndex : pageIndex + 1;
        await _nextButtonHandler(ctx, maxPageCount, pageIndex, lbMessage);
      } else if (eventValue == "lb_delete") {
        event.acknowledge();
        await lbMessage.edit(ComponentMessageBuilder()
          ..content = "Prompt terminated."
          ..componentRows = []
          ..allowedMentions = _allowedMentions);
        return;
      }
    });
  }

  Future<void> _nextButtonHandler(
      TextCommandContext ctx, int maxPageCount, int pageIndex, IMessage lbMessage) async {
    /// adjust buttons
    /// edit message
  }

  Future<void> _prevButtonHandler(
      TextCommandContext ctx, int maxPageCount, int pageIndex, IMessage lbMessage) async {
    /// adjust buttons
    /// edit message
  }

  Future<String> _generatePage(TextCommandContext ctx,
      {int pageIndex = 0, int pageMaxRows = maxRowsPerPage}) async {
    if (pages.containsKey(pageIndex)) {
      return pages[pageIndex]!;
    }

    CCDatabase db = CCDatabase(initializing: false);

    StringBuffer outputBuffer = StringBuffer();
    Iterator<ResultSetRow> rowIterator =
        await db.leaderboardSelection(ctx.guild!.id.id, pageNumber: pageIndex, pageEntryMax: pageMaxRows);

    while (rowIterator.moveNext()) {
      var thisRow = rowIterator.current.typedAssoc();
      Snowflake userID = Snowflake(thisRow["user_id"]);

      IUser? user = ctx.client.users[userID];
      user ??= await ctx.client.httpEndpoints.fetchUser(userID);
      ctx.client.users.putIfAbsent(userID, () => user!);

      outputBuffer.writeln("**${thisRow["row_num"]}.** ${user.tag} - `${thisRow["cookies"]}`");
    }

    String output = outputBuffer.toString();
    pages[pageIndex] = output;
    return output;
  }
}
