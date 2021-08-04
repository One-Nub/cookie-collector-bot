import 'dart:collection';
import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commander/commander.dart';

import 'package:mysql1/mysql1.dart';
import '../../core/CCDatabase.dart';
import '../../framework/commands/Cooldown.dart';
import '../../framework/argument/UserArgument.dart';
import '../../framework/exceptions/ArgumentNotRequired.dart';
import '../../framework/exceptions/InvalidUserException.dart';


class Rob extends Cooldown {
  late AllowedMentions _mentions;
  late CCDatabase _database;
  static const minCookieCountToRob = 15;
  static const minVictimCookieCount = 20;

  ///Snowflake: Guild ID
  ///Guild users map:
  /// Snowflake: User ID
  /// List: 10 bools, 3 of which will be true, 7 false.
  Map<Snowflake, Map<Snowflake, Queue<bool>>> _userRobRate = {};

  Rob(this._database) : super(Duration(hours: 3)) {
    _mentions = AllowedMentions()..allow(reply: false, users: false);
  }

  ///Ensures that the command is run in a guild
  ///Checks that the user is not on a cooldown
  ///Checks that the user has at least minCookieCountToRob cookies before robbing
  Future<bool> preRunChecks(CommandContext ctx, CCDatabase _database) async {
    if(ctx.guild == null) {
      return false;
    }

    if(super.isCooldownActive(ctx.guild!.id, ctx.author.id)) {
      ctx.reply(MessageBuilder.content("Your prep time has not expired yet! You can rob someone in "
        "`${super.getRemainingTime(ctx.guild!.id, ctx.author.id)}`")
        ..allowedMentions = _mentions);
      return false;
    }

    int userCookies = await _database.getCookieCount(ctx.author.id.id, ctx.guild!.id.id);
    if(userCookies < minCookieCountToRob) {
      ctx.reply(MessageBuilder.content("Hold up there partner! You need at least "
        "$minCookieCountToRob cookies to rob people! Debt isn't allowed round here")
        ..allowedMentions = _mentions);
      return false;
    }

    return true;
  }

  ///Post preRunChecks, gets an optional user argument from the message
  ///Confirms that the user isn't robbing themselves, that the victim exists in the
  ///database, and that the victim has a minimum amount of cookies.
  ///
  ///Selects random victim if no victim is found unless user is searching for a specific
  ///victim where then the user will be told no matching victim is found.
  Future<void> argumentParser(CommandContext ctx, String msg) async {
    Map<String, dynamic> victimMap = {};

    msg = msg.replaceFirst(" ", "");
    msg = msg.replaceFirst(ctx.commandMatcher, "");
    var victimArg = UserArgument(searchMemberNames: true);

    try {
      User victimUser = await victimArg.parseArg(ctx, msg);
      if(victimUser.id.id == ctx.author.id.id) {
        await ctx.reply(MessageBuilder.content("I don't think you can rob yourself... right?")
          ..allowedMentions = _mentions);
        return;
      }

      ResultRow? victim = await _database.getUserGuildData(victimUser.id.id, ctx.guild!.id.id);
      if(victim == null) {
        await ctx.reply(MessageBuilder.content("That user could not be found in the database.")
          ..allowedMentions = _mentions);
        return;
      }
      victimMap = victim.fields;

      if(victimMap["cookies"] < minVictimCookieCount) {
        await ctx.reply(MessageBuilder.content("This user doesn't have enough cookies to be robbed from!")
          ..allowedMentions = _mentions);
        return;
      }
    }
    on ArgumentNotRequiredException {
      //Get random user
      ResultRow? victim = await _database.getRandomUserToRob(ctx.guild!.id.id,
        ctx.author.id.id, minVictimCookieCount);
      if(victim == null) {
        await ctx.reply(MessageBuilder.content("Nobody can be robbed at this time, sorry!")
          ..allowedMentions = _mentions);
        return;
      }
      victimMap = victim.fields;
    }
    on InvalidUserException catch (e) {
      await ctx.reply(MessageBuilder.content(e.toString())
        ..allowedMentions = _mentions);
      return;
    }

    commandFunction(ctx, msg, victimMap);
  }

  Future<void> commandFunction(CommandContext ctx, String msg, Map<String, dynamic> victimMap) async {
    const int low = 5;
    const int high = 10;
    const double lowPercentMult = 0.008; //0.8%
    const double highPercentMult = 0.016; //0.16%

    String missionResult = "";
    User victimUser = await ctx.client.fetchUser(Snowflake(victimMap["user_id"]));

    //Used for both success and failure
    int randomAmt = Random.secure().nextInt(high - low) + low;
    bool robResult = _robSuccessHandler(ctx.guild!.id, ctx.author.id);

    if(robResult) {
      if(victimMap["cookies"] > 100 && victimMap["cookies"] < 1500) {
        randomAmt += (victimMap["cookies"] * highPercentMult).round() as int;
      }
      else if (victimMap["cookies"] >= 1500) {
        //Reduce amount taken from users with high cookie counts (balancing)
        randomAmt += (victimMap["cookies"] * lowPercentMult).round() as int;
      }

      _database.addCookies(ctx.author.id.id, randomAmt, ctx.guild!.id.id);
      _database.addLifetimeCookies(ctx.author.id.id, randomAmt, ctx.guild!.id.id);
      _database.removeCookies(victimUser.id.id, randomAmt, ctx.guild!.id.id);

      String successMsg = _successMessages[Random().nextInt(_successMessages.length)];
      missionResult = "You stole `$randomAmt` cookies from "
        "${victimUser.mention} (${victimUser.tag}) by $successMsg!";
    }
    else {
      int robberCookies = await _database.getCookieCount(ctx.author.id.id, ctx.guild!.id.id);
      int taxAmount = (robberCookies * lowPercentMult).round();

      //Prevents tax from making cookie count negative
      if(robberCookies - randomAmt > taxAmount) {
        randomAmt += taxAmount;
      }

      await _database.removeCookies(ctx.author.id.id, randomAmt, ctx.guild!.id.id);

      String failMsg = _failMessages[Random().nextInt(_failMessages.length)];
      missionResult = "You failed at robbing ${victimUser.mention} (${victimUser.tag}) "
        "because $failMsg, so you lost `$randomAmt` cookies.";
    }

    EmbedBuilder resultEmbed = EmbedBuilder()
      ..color = robResult ? DiscordColor.fromHexString("67F399") :
        DiscordColor.fromHexString("6B0504")
      ..description = missionResult
      ..title = "Robbery Result!";

    ctx.reply(MessageBuilder.embed(resultEmbed)..allowedMentions = _mentions);
    super.applyCooldown(ctx.guild!.id, ctx.author.id);
  }

  ///Handles the rob chance queue, removes latest
  ///If queue is empty or missing, calls for a new queue for the user
  bool _robSuccessHandler(Snowflake guildID, Snowflake userID) {
    //Create map for guild if it doesn't exist
    _userRobRate.putIfAbsent(guildID, () => {});
    //Get map of users for guild
    Map<Snowflake, Queue<bool>> userMap = _userRobRate[guildID]!;

    //Generate rob chance for user if their key doesn't exist or their queue is empty
    if(userMap.isEmpty || !userMap.containsKey(userID) || userMap[userID]!.isEmpty) {
      userMap[userID] = _generateRobChance();
    }
    Queue<bool> robResultQueue = userMap[userID]!;
    return robResultQueue.removeFirst();
  }

  ///Creates a list of bools, 3 of which are true out of 10.
  ///Then shuffles the list and converts to a queue
  Queue<bool> _generateRobChance() {
    List<bool> robChanceList = [];
    for(int i = 0; i < 10; i++) {
      //30% success rate
      if(i < 3) {
        robChanceList.add(true);
      }
      else {
        robChanceList.add(false);
      }
    }
    //Randomize the list
    robChanceList.shuffle(Random.secure());
    return Queue.from(robChanceList);
  }
}


//by...
//24 so far
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
  "beating them in the pyramid scheme",
  "reaching into their pocket while they weren't looking",
  "taking their portable cookie jar",
  "acting like a homeless person; where are your morals bro smh",
  "selling their stocks secretly",
  "you convinced them to invest in stonks",
  "convincing them they had the plague, and that paying you would cure it",
  "getting them join your *exclusive* discord server",
  "stuffing them in your cheeks like a chipmunk while they were cooling",
  "trading them with some plastic cookies",
  "hosting a cookie party but sneaking out to their safe",
  "begging a lot, like *a lot*..."
];

//because...
//34 so far
final List<String> _failMessages = [
  "you walked by the police office with your bag of cookies",
  "Nub ate your getaway car, tough luck bro",
  "the window was made of acrylic",
  "you left your mask in the van and you didn't feel like getting it",
  "it was as if you were never there",
  "even I can steal better than you, smh",
  "the neighbor's dog needed belly rubs",
  "you left the note for your crush behind that you signed for some reason...",
  "the cookie jar was too well protected & you were too lazy to deal with that",
  "the cookie jar was actually fake, causing you to fall into a trap",
  "it was too hot outside",
  "it was too cold outside",
  "you actually tried to rob the police station",
  "you told them in advance you were going to rob them, nice job mate",
  "you felt bad and called the police and told them",
  "you tripped and all your stolen cookies fell down the storm drain",
  "you woke up",
  "you ~~somehow~~ fell in love with John and left your profits behind",
  "after a nice robbery, you realize you forgot one thing: the cookies",
  "that's just how the cookie crumbles",
  "all they had were stupid coins and not any cookies",
  "for some reason they had oatmeal cookies, like who eats those?",
  "your browser said delete cookies and you said yes",
  "your house was set on fire by the person you robbed",
  "I said so :eyes:",
  "you were too comfy in bed. so you slept through the robbery",
  "you threw out your plans while cleaning",
  "you had a change of heart and left your robberies for the day behind",
  "the neighbor's dog tackled you, or was that nub...",
  "someone saw you put your very unsuspicious ski mask on",
  "the weather was too nice, so you went to the beach instead",
  "the weather was so bad, it would've been impossible anyway",
  "there was a minecraft bedwars tournament",
  "Technoblade showed up and screamed \"DONDE ESTA LA BIBLIOTECA\" as he took the cookies for himself"
];
