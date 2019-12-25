//This file has the main functionality - letting users collect cookies of a
//random amount if 2+ people are typing in chat.
part of commands;

const conversationDelay = 15; //seconds
const lastSuccessDelay = 180; //seconds
const List<String> collectTriggers = [
  "collect",
  "nab",
  "yoink",
  "pick",
  "steal",
  "grab",
  "mine",
  "john"
];

//Testing channels
/*const listenCategory  = 658437900979011630; //Category to listen to messages in
const sendChannelID   = 440350951572897814;
const guildID         = 440350951572897812; */

//Release channels
const listenCategory  = 438843373961609227; //Category to listen to messages in
const sendChannelID   = 614266653332733952;
const guildID         = 438843373961609226;

Message prev;
DateTime prevTime;
DateTime lastSuccess;

void cookieTriggerListener() async {
  bot.onMessageReceived.listen((event) {
    TextChannel eventTxtChannel = event.message.channel;

    //All the scenarios where it should not do anything.
    if (event.message.author.bot ||
        (eventTxtChannel is DMChannel) ||
        (eventTxtChannel.parentChannel == null)) {
      return;
    }

    if (prev == null) {
      prev = event.message;
      prevTime = event.message.createdAt;
      return;
    }

    //Restricts the command to one guild. (aka not public)
    if (prev != null && event.message.guild.id.toInt() != guildID) {
      return;
    }

    //Enforces delay of command triggering. Saves a bit of processing if it's
    //up here rather than at command call.
    if (lastSuccess != null) {
      Duration timeFromSuccess =
          event.message.createdAt.difference(lastSuccess);
      if (timeFromSuccess.inSeconds < lastSuccessDelay) return;
    }

    //Ensures it's not the same person
    if (prev.author != event.message.author) {
      Duration timeBetweenMsg = event.message.createdAt.difference(prevTime);

      //Ensures people are responding in a reasonable fashion
      //and not >conversationDelay later to grab free cookies
      if (timeBetweenMsg.inSeconds > conversationDelay) {
        prevTime = event.message.createdAt;
        prev = event.message;
        return;
      } else {
        //Manually creates a command context for the bot.
        CommandContext ctx = CommandContext()
          ..author = bot.self
          ..client = bot
          ..guild = event.message.guild
          ..message = event.message;
        //Triggers the command
        sendCookies(ctx);
        prev = null;
        prevTime = null;
      }
    }
  });
}

Future<void> sendCookies(CommandContext ctx) async {
  //Hardcoding a channel to send to for now - when I setup a database maybe
  //I'll make it a setting to choose which channel to send to
  Snowflake channelID = Snowflake(sendChannelID);
  TextChannel channel = await bot.getChannel(channelID);
  ctx.channel = channel;
  String prefix = prefixHandler.prefix;
  var collectEmbed = EmbedBuilder();
  var numCookies = 1 + Random().nextInt(4);
  var randomSelection = Random().nextInt(collectTriggers.length - 1);
  var randomKeyword = "$prefix${collectTriggers[randomSelection]}";

  collectEmbed.title = randomKeyword;
  collectEmbed.description =
      "Say that to collect **$numCookies** cookies! (Or don't that's on you...)";

  var pluralization = "";
  if (numCookies == 1)
    pluralization = "**$numCookies** cookie!";
  else
    pluralization = "**$numCookies** cookies!";

  Message collectMe = await channel.send(embed: collectEmbed);
  lastSuccess = collectMe.createdAt;

  //TODO: Add a timeout for this so that after ~1 minutes it'll auto delete
  var userResponse = await ctx.nextMessagesWhere(
      (msg) => msg.message.content.toLowerCase() == collectEmbed.title,
      limit: 1);
  userResponse.listen((event) async {
    await collectMe.delete();
    await event.message.delete();
    await ctx.replyTemp(Duration(seconds: 3),
        content: "${event.message.author.mention} collected $pluralization");

    await db.add_cookies(
        event.message.author.id.toInt(), numCookies, ctx.guild.id.toInt());
  });
}
