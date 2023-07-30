import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:mysql_client/mysql_client.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCBot.dart';
import '../../core/CCDatabase.dart';
import '../../core/CCRedis.dart';
import '../../utilities/parse_id.dart';
import '../../utilities/event_tiers.dart';

/// String is guildid-userid, queue is a t/f list.
final Map<String, Queue<bool>> robChances = Map();

const Duration _randomCooldown = Duration(hours: 3);
const Duration _specificCooldown = Duration(hours: 8);

const Duration _t1CooldownRandom = Duration(minutes: 90);
const Duration _t2CooldownRandom = Duration(minutes: 45);
const Duration _t3CooldownRandom = Duration(minutes: 30);

const Duration _t1CooldownSpecific = Duration(hours: 2);
const Duration _t2CooldownSpecific = Duration(minutes: 75);
const Duration _t3CooldownSpecific = Duration(minutes: 60);

const minCookieCount = 15;
const minVictimCookieCount = 20;

const int robVarLow = 5;
const int robVarHigh = 10;
const double lowPercentMult = 0.008; //0.8%
const double highPercentMult = 0.016; //0.16%

class RobCommand extends TextCommand {
  @override
  String get name => "rob";

  @override
  String get description => "Rob a random user! Be careful, you may not always succeed...";

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    int authorID = ctx.author.id.id;

    if (ctx.guild == null) {
      await ctx.channel.sendMessage(MessageBuilder.content("You can't use this command in DMs!")
        ..allowedMentions = (AllowedMentions()..allow(reply: false))
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
      return;
    }

    int guildID = ctx.guild!.id.id;

    CCRedis redis = CCRedis();
    int? robCooldown = await redis.getRobCooldown(guildID, authorID);
    int userTier = await getUserTier(authorID, guildID: guildID);

    if (robCooldown != null) {
      // check cooldown
      DateTime cooldownExpiry = DateTime.fromMillisecondsSinceEpoch(robCooldown);

      /// check to see if current cooldown is longer than longest cooldown duration for their tier.
      cooldownExpiry = await _tieredCooldownCheck(cooldownExpiry, userTier, guildID, authorID);

      if (cooldownExpiry.isAfter(DateTime.now())) {
        ctx.channel
            .sendMessage(MessageBuilder.content("Your prep time has not expired yet! You can rob someone "
                "<t:${(cooldownExpiry.millisecondsSinceEpoch / 1000).round()}:R>.")
              ..allowedMentions = (AllowedMentions()..allow(reply: false))
              ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
        return;
      }
    }

    CCDatabase db = CCDatabase(initializing: false);
    int authorCookies = await db.getCookieCount(authorID, guildID);
    // check author cookie count
    if (authorCookies < minCookieCount) {
      ctx.channel.sendMessage(MessageBuilder.content("Hold up there partner! You need at least "
          "$minCookieCount cookies to rob people! Debt isn't allowed round here")
        ..allowedMentions = (AllowedMentions()..allow(reply: false))
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
      return;
    }

    IResultSet? victimUserSet;
    if (args.isNotEmpty) {
      int? victimID = parseID(args.first);
      if (victimID == null) {
        ctx.channel.sendMessage(MessageBuilder.content("That doesn't look like a valid user ID to me! "
            "Please @ someone or put their ID in instead.")
          ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
          ..allowedMentions = (AllowedMentions()..allow(reply: false)));
        return;
      }

      if (victimID == ctx.author.id.id) {
        ctx.channel
            .sendMessage(MessageBuilder.content("You can't rob yourself! What is this, the Great Depression?")
              ..replyBuilder = ReplyBuilder.fromMessage(ctx.message)
              ..allowedMentions = (AllowedMentions()..allow(reply: false)));
        return;
      }

      victimUserSet = await db.getUserGuildData(victimID, guildID);
      if (victimUserSet == null || victimUserSet.rows.isEmpty) {
        ctx.channel.sendMessage(MessageBuilder.content(
            "Your victim doesn't exist... In the database that is, get them to run `.daily` first!")
          ..allowedMentions = (AllowedMentions()..allow(reply: false))
          ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
        return;
      }

      int victimCookieCnt = (victimUserSet.rows.first.typedAssoc())["cookies"];
      if (victimCookieCnt < minVictimCookieCount) {
        ctx.channel.sendMessage(
            MessageBuilder.content("Your victim need more cookies before they can be robbed from!")
              ..allowedMentions = (AllowedMentions()..allow(reply: false))
              ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
        return;
      }

      bool result = await _confirmRobbery(ctx: ctx, victimID: victimID, userTier: userTier);
      if (!result) return;

      Duration cooldown = await _determineCooldown(guildID, authorID, isRandom: false, userTier: userTier);
      redis.setRobCooldown(guildID, authorID, DateTime.now().add(cooldown), ttl: cooldown);
      // ignore: unnecessary_null_comparison
    } else if (victimUserSet == null) {
      victimUserSet = await db.getRandomUserToRob(guildID, authorID, minVictimCookieCount);
      if (victimUserSet == null || victimUserSet.rows.isEmpty) {
        ctx.channel.sendMessage(
            MessageBuilder.content("Nobody could be robbed at this time, sorry! Might want to consider "
                "moving out of your ghost town..")
              ..allowedMentions = (AllowedMentions()..allow(reply: false))
              ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
        return;
      }

      Duration cooldown = await _determineCooldown(guildID, authorID, isRandom: true, userTier: userTier);
      redis.setRobCooldown(guildID, authorID, DateTime.now().add(cooldown), ttl: cooldown);
    }

    /// This could be done in redis, but I honestly don't think it needs to be in redis.
    String mapEntry = "$guildID-$authorID";
    if (!robChances.containsKey(mapEntry)) {
      // generate rob queue first if it doesn't exist
      robChances[mapEntry] = _resetQueue(userTier: userTier);
    } else if (robChances[mapEntry]!.isEmpty) {
      // generate rob queue if the current one is empty
      robChances[mapEntry] = _resetQueue(userTier: userTier);
    }

    var victimData = victimUserSet.rows.first.typedAssoc();
    bool robResult = robChances[mapEntry]!.removeFirst();

    if (robResult) {
      await _robSuccess(ctx, victimData, db);
    } else {
      await _robFailure(ctx, authorCookies, victimData, db);
    }
  }

  Future<bool> _confirmRobbery(
      {required TextCommandContext ctx, required int victimID, required int userTier}) async {
    var bot = CCBot();
    var interactions = bot.interactions;

    ComponentMessageBuilder cmb = ComponentMessageBuilder();
    IUser? victimUser = ctx.client.users[victimID];
    if (victimUser == null) {
      victimUser = await ctx.client.httpEndpoints.fetchUser(Snowflake(victimID));
    }

    Duration randomCooldown = _randomCooldown;
    Duration specificCooldown = _specificCooldown;
    if (userTier == 1) {
      randomCooldown = _t1CooldownRandom;
      specificCooldown = _t1CooldownSpecific;
    } else if (userTier == 2) {
      randomCooldown = _t2CooldownRandom;
      specificCooldown = _t2CooldownSpecific;
    } else if (userTier == 3) {
      randomCooldown = _t3CooldownRandom;
      specificCooldown = _t3CooldownSpecific;
    }

    cmb.content = "Please confirm that you want to rob **${victimUser.tag}**.\n"
        "Be careful... You will have to wait `${specificCooldown.inMinutes} minutes` rather "
        "than the normal `${randomCooldown.inMinutes} minutes` before you can rob again.";
    cmb.componentRows = [
      ComponentRowBuilder()
        ..addComponent(ButtonBuilder("Deny", "deny", ButtonStyle.danger))
        ..addComponent(ButtonBuilder("Approve", "approve", ButtonStyle.success))
    ];

    bool accept = false;
    var confirmMsg = await ctx.channel.sendMessage(cmb);
    try {
      var buttonEvent = await interactions.events.onButtonEvent.firstWhere((element) {
        return element.interaction.userAuthor!.id == ctx.message.author.id &&
            (element.interaction.customId == "deny" || element.interaction.customId == "approve");
      }).timeout(Duration(seconds: 15));

      String buttonID = buttonEvent.interaction.customId;
      if (buttonID == "deny") {
        await confirmMsg.delete();

        await buttonEvent.acknowledge();
        await buttonEvent.sendFollowup(MessageBuilder.content("Robbery cancelled. Quick, scram!"),
            hidden: true);
        accept = false;
      } else if (buttonID == "approve") {
        await confirmMsg.delete();
        await buttonEvent.acknowledge();
        accept = true;
      }
    } on TimeoutException {
      await confirmMsg.delete();
      await ctx.channel.sendMessage(MessageBuilder.content("Robbery cancelled. Quick, scram!")
        ..allowedMentions = (AllowedMentions()..allow(reply: false))
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
      accept = false;
    } finally {
      return accept;
    }
  }

  Future<void> _robSuccess(TextCommandContext ctx, Map<String, dynamic> victimData, CCDatabase db) async {
    int stolenCount = Random.secure().nextInt(robVarHigh - robVarLow) + robVarLow;
    int victimCookieCnt = victimData["cookies"];

    if (victimCookieCnt > 100 && victimCookieCnt < 1500) {
      stolenCount += (victimCookieCnt * highPercentMult).round();
    } else if (victimCookieCnt >= 1500) {
      stolenCount += (victimCookieCnt * lowPercentMult).round();
    }

    int authorID = ctx.author.id.id;
    int guildID = ctx.guild!.id.id;
    int victimID = victimData["user_id"];

    // these should be grouped or in a transaction in good practice... consider doing that
    await db.addCookies(authorID, stolenCount, guildID);
    await db.addLifetimeCookies(authorID, stolenCount, guildID);
    await db.removeCookies(victimID, stolenCount, guildID);

    var bot = CCBot();
    var victimUser = await bot.gateway.fetchUser(Snowflake(victimID));

    String successMsg = _successMessages[Random.secure().nextInt(_successMessages.length)];
    String missionResult = "You stole `$stolenCount` cookies from ${victimUser.mention} (${victimUser.tag}) "
        "by $successMsg.";

    EmbedBuilder resultEmbed = EmbedBuilder()
      ..color = DiscordColor.fromHexString("67F399")
      ..description = missionResult
      ..title = "Robbery Result!";

    await ctx.channel.sendMessage(MessageBuilder.embed(resultEmbed)
      ..allowedMentions = (AllowedMentions()..allow(reply: false))
      ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
  }

  Future<void> _robFailure(
      TextCommandContext ctx, int authorCookies, Map<String, dynamic> victimData, CCDatabase db) async {
    int lostAmount = Random.secure().nextInt(robVarHigh - robVarLow) + robVarLow;
    int taxAmount = (authorCookies * lowPercentMult).round();

    if (authorCookies - lostAmount > taxAmount) {
      lostAmount += taxAmount;
    }

    await db.removeCookies(ctx.author.id.id, lostAmount, ctx.guild!.id.id);

    var bot = CCBot();
    var victimUser = await bot.gateway.fetchUser(Snowflake(victimData["user_id"]));

    String failMsg = _failMessages[Random.secure().nextInt(_failMessages.length)];
    String missionResult = "You failed at robbing ${victimUser.mention} (${victimUser.tag}) "
        "because $failMsg, so you lost `$lostAmount` cookies.";

    EmbedBuilder resultEmbed = EmbedBuilder()
      ..color = DiscordColor.fromHexString("6B0504")
      ..description = missionResult
      ..title = "Robbery Result!";

    await ctx.channel.sendMessage(MessageBuilder.embed(resultEmbed)
      ..allowedMentions = (AllowedMentions()..allow(reply: false))
      ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
  }

  Queue<bool> _resetQueue({int userTier = 0}) {
    // 30% when combined
    List<bool> chanceFirst = [false, true, false];
    List<bool> chanceSecond = [false, true, false, false];
    List<bool> chanceThird = [false, true, false];

    if (userTier == 2) {
      // 40%
      chanceSecond[2] = true;
    } else if (userTier == 3) {
      // 50%
      chanceFirst[0] = true;
      chanceSecond[3] = true;
    }

    chanceFirst.shuffle(Random.secure());
    chanceSecond.shuffle(Random.secure());
    chanceThird.shuffle(Random.secure());

    print("$chanceFirst, $chanceSecond, $chanceThird");
    return Queue.from([...chanceFirst, ...chanceSecond, ...chanceThird]);
  }
}

Future<Duration> _determineCooldown(int guildID, int userID, {required bool isRandom, int? userTier}) async {
  int tierResult = (userTier == null) ? await getUserTier(userID, guildID: guildID) : userTier;

  switch (tierResult) {
    case 1:
      return (isRandom) ? _t1CooldownRandom : _t1CooldownSpecific;
    case 2:
      return (isRandom) ? _t2CooldownRandom : _t2CooldownSpecific;
    case 3:
      return (isRandom) ? _t3CooldownRandom : _t3CooldownSpecific;
    default:
      return (isRandom) ? _randomCooldown : _specificCooldown;
  }
}

/// Check if a user has a cooldown longer than the tier that they are subscribed to.
/// If so, update the cooldown to the cooldown of their tier. If not, don't change anything.
///
/// In the instance there should be no change, the [currentCooldown] DateTime is returned, otherwise
/// an updated datetime should be returned.
Future<DateTime> _tieredCooldownCheck(DateTime currentCooldown, int userTier, int guildID, int userID) async {
  if (userTier == 0) return currentCooldown;

  Duration maxCooldownDuration;

  /// Specific cooldowns are used since this checks every time the cmd is run.
  /// This means that if someone robs someone specific then tries again,
  /// if the cooldown check for someone random was used, their cooldown would
  /// instantly be reduced to the lower of the two, which we don't want.
  ///
  /// This just means for first increase ppl, it will be the 'higher' cooldown,
  /// not too big of a deal if it's just a one time occurrence imo.
  if (userTier == 1) {
    maxCooldownDuration = _t1CooldownSpecific;
  } else if (userTier == 2) {
    maxCooldownDuration = _t2CooldownSpecific;
  } else {
    maxCooldownDuration = _t3CooldownSpecific;
  }

  DateTime modDuration = DateTime.now().add(maxCooldownDuration);

  if (modDuration.isBefore(currentCooldown)) {
    /// Update the cooldown.
    CCRedis redis = CCRedis();
    redis.setRobCooldown(guildID, userID, modDuration, ttl: maxCooldownDuration);
    return modDuration;
  } else {
    return currentCooldown;
  }
}

//by...
final List<String> _successMessages = [
  "dodging the wild bork and crawling in through the doggy door",
  "making them pay for the dinner date",
  "going inside the unlocked door while they were on vacation",
  "grabbing the fresh cookies from the windowsill, rookie mistake on their part",
  "calling them 24/7, so they paid you to go away",
  "tripping them on the walk home from school... you bully :frowning:",
  "bullying them for their lunch money",
  "taking care of their dog... They left the cookie jar out ok",
  "ratting their hidden robberies out to the police",
  "calling the IRS on them... Cookie Government needs its cookies bro",
  "reaching inside the open window and into the cookie jar",
  "taking it in the divorce... It was a long con alright",
  "being their boss in the latest pyramid scheme, an automatic cookie-eater",
  "reaching into their pocket while they weren't looking",
  "taking their portable cookie jar",
  "acting like a homeless person; where are your morals bro smh",
  "selling their stocks secretly",
  "you convinced them to invest in your stocks - which you then trashed the next day",
  "convincing them they had the plague, and that paying you would cure it",
  "getting them join your *exclusive* discord server :eyes:",
  "stuffing them in your cheeks like a chipmunk while they were cooling",
  "trading them with some plastic cookies",
  "hosting a cookie party but sneaking out to their safe",
  "begging a lot, like *a lot*...",
  "stealing the secret krabby patty recipe, and then swapping it with their cookies",
  "distracting them with some cool dance moves, until you karate chopped their neck.."
];

//because...
final List<String> _failMessages = [
  "you walked by the police office with your bag of cookies (very suspiciously)",
  "Nub ate your getaway car, tough luck bro, he said it was tasty though",
  "the window was made of acrylic, so it wouldn't break",
  "you left your mask in the van and you didn't feel like getting it",
  "it was as if you were never there :ghost:",
  "even I can steal better than you, smh",
  "the neighbor's dog needed belly rubs",
  "you dropped the note that was supposed to be for your date...",
  "the cookie jar was too well protected & you were too lazy to deal with that",
  "the cookie jar was actually fake, causing you to fall into a trap",
  "it was too hot outside",
  "it was too cold outside",
  "your intelligence gave you the address of the police station instead",
  "you told them in advance you were going to rob them, very courteous",
  "you felt bad and called off the robbery last minute",
  "you tripped and all your stolen cookies fell down a storm drain",
  "you woke up from your coma",
  "you ~~somehow~~ fell in love with John and left your profits behind",
  "after a nice robbery, you realize you forgot one thing: the cookies",
  "that's just how the cookie crumbles",
  "all they had were stupid coins and not any cookies",
  "for some reason they had oatmeal cookies, like who eats those?",
  "your browser said \"Delete cookies?\" and you said yes",
  "your house was set on fire by the person you robbed",
  "I said so :eyes:",
  "you were too comfy in bed. so you slept through the robbery",
  "you threw out your plans while cleaning",
  "you had a change of heart and left your robberies for the day behind",
  "the neighbor's dog tackled you, or was that nub...",
  "someone saw you put your very unsuspicious ski mask on in front of the door",
  "the weather was too nice, so you went to the beach instead",
  "the weather was so bad, it would've been impossible anyway",
  "there was a concert that you just HAD to go to instead",
  "your favorite livestreamer was too distracting, so you missed the deadline",
  "you were too busy making TikToks explaining how robbers take cookies",
  "you crashed your getaway car into Nub's house, now where is he gonna live? :(",
  "you saw John in the distance and wanted his autograph, but then he talked too much so you missed the cut-off time",
  "Boba drank your car's getaway fuel, L"
];
