part of commands;

var _robCooldown = UserBasedCache();
var _recentlyRobbed = UserBasedCache();

@UserProcessor()
@Restrict(requiredContext: ContextType.guild)
@Command("rob", aliases: ["steal"])
Future<void> rob(CommandContext ctx, [User broke]) async {
  Snowflake authorSnflk = ctx.author.id;
  Snowflake brokeSnflk = broke.id;
  int brokeId = broke.id.toInt();
  int authorId = authorSnflk.toInt();
  int guildId = ctx.guild.id.toInt();
  var nowUtc = DateTime.now().toUtc();
  Duration robCoolOffset = new Duration(hours: 3);
  Duration prevRobbedOffset = new Duration(hours: 1);

  //Prevent self robbing
  if(brokeId == authorId) {
    await ctx.message.reply(content: "You can't rob yourself... Can you?");
    return;
  }

  //Cooldown check
  if (_robCooldown.hasKey(authorSnflk) &&
    _robCooldown[authorSnflk].isAfter(nowUtc)) {
      String timeDiff = _robCooldown[authorSnflk].difference(nowUtc).toString();
      var timeSplit = timeDiff.split(":");
      var remainingTime = "`${timeSplit[0]} hours, ${timeSplit[1]} minutes, "
      "and ${timeSplit[2].substring(0, 2)} seconds`";

      await ctx.message.reply(content: "Your government induced cooldown has not"
        " expired yet. You can rob again in $remainingTime");
      return;
  }

  //Cooldown for person who's been robbed, hopefully to ward off targeting
  if (_recentlyRobbed.hasKey(brokeSnflk) &&
    _recentlyRobbed[brokeSnflk].isAfter(nowUtc)) {
      await ctx.message.reply(content: "This user has been robbed recently. "
        "Try again later, or rob someone else.");
      return;
  }

  //Cookie limit for person getting robbed
  int brokeCookieCount = await db.get_cookies(brokeId, guildId);
  if (await brokeCookieCount < 15) {
    await ctx.message.reply(
        content: "This user doesn't have at least `15` cookies!");
    return;
  }

  //Cookie limit for the robber (in case they fail)
  int authorCookieCount = await db.get_cookies(authorSnflk.toInt(), guildId);
  if(authorCookieCount < 10) {
    ctx.message.reply(content: "You need at least `10` cookies to rob from "
      "people! Why? \nDon't ask me, ask the government ok");
    return;
  }

  //Robbing the user
  int stolenAmt = await robUser(authorId, brokeId, brokeCookieCount, guildId);
  if (stolenAmt != 0) {
    String successMsg = _successMessages[Random().nextInt(_successMessages.length - 1)];
    //No DB calls because that's handled in the robUser method.
    await ctx.message.reply(content: "You obtained `$stolenAmt` cookies from "
      "<@$brokeId> by $successMsg");
    await _recentlyRobbed.add(brokeSnflk, nowUtc.add(prevRobbedOffset));
  }
  else {
    String failMsg = _failMessages[Random().nextInt(_failMessages.length - 1)];
    int lostCookies = 5 + Random().nextInt(10 - 5); //At least 5, at most 10
    //Tax user of 1% of their current cookies
    int cookieTax = (authorCookieCount * .01).round();

    await db.remove_cookies(authorId, lostCookies + cookieTax, guildID);
    String response = "You failed the robbery because $failMsg, plus "
      "you lost `$lostCookies` extra cookies on gas money";
    if(cookieTax > 0) {
      response += " and `$cookieTax` cookie(s) to the Cookie Government (darn taxes)";
    }
    await ctx.message.reply(content: response);
  }
  _robCooldown.add(authorSnflk, nowUtc.add(robCoolOffset));
  await ctx.message.reply(content: "You can rob again in "
    "`${robCoolOffset.inHours} hours`.", mention: false);
}

//0 is a failure, any other number will be a success
Future<int> robUser(int authorId, int brokeId, int userCookies, int guildId) async {
  if(Random().nextDouble() > 0.4)
    return 0; //40% chance of success

  int removeVal = userCookies < 100 ?
    5 + Random().nextInt(15 - 5) :
    (5 + Random().nextInt(15 - 5) + (userCookies * .025).round());
    //If the user has over 100 cookies, add 2.5% of their cookies on top
    //of what they're randomly losing

  await db.remove_cookies(brokeId, removeVal, guildId);
  await db.add_cookies(authorId, removeVal, guildId);

  return removeVal;
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
  "beating them in the pyramid scheme",
  "reaching into their pocket while they weren't looking",
  "taking their portable cookie jar",
  "acting like a homeless person; where are your morals bro smh",
  "selling their stocks secretly",
  "you convinced them to invest in stonks",
  "convincing them they had the plague, and that paying you would cure it"
];

final List<String> _failMessages = [
  "you walked by the police office with your bag of cookies",
  "Nub ate your getaway car, tough luck bro",
  "the window was made of acrylic",
  "you left your mask in the van and you didn't feel like getting it",
  "it was as if you were never there",
  "even I can steal better than you, smh",
  "the neighbor's dog needed belly rubs",
  "you left the note for your crush behind, that you signed for some reason...",
  "the cookie jar was too well protected & you were too lazy to deal with that",
  "the cookie jar was actually fake, causing you to fall into a trap",
  "it was too hot outside",
  "it was too cold outside",
  "you actually tried to rob the police station",
  "you told them in advance you were going to rob them, nice job mate",
  "you felt bad and called the police and told them",
  "you tripped and all your stolen cookies fell down the storm drain",
  "you woke up",
  "after a nice robbery, you realize you forgot one thing: the cookies",
  "that's just how the cookie crumbles",
  "all they had were stupid coins and not any cookies",
  "for some reason they had oatmeal cookies, like who eats those?",
  "your browser said delete cookies and you said yes",
  "your house was set on fire by the person you robbed",
  "I said so :eyes:",
  "you ~~somehow~~ fell in love with John and left your profits behind"
];
