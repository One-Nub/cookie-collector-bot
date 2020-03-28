part of commands;

@Restrict(requiredContext: ContextType.guild)
@Command("stats")
Future<void> stats(CommandContext ctx, [String user]) async {
  int userID = 0;
  if(user != "") {
    user = user.replaceAll(RegExp("[<@!>]"), "");
    userID = int.parse(user);
  } else userID = ctx.author.id.toInt();

  Iterator userIterator = await db.get_user(userID, ctx.guild.id.toInt());
  userIterator.moveNext();
  Map dbValues = userIterator.current.fields;
  User member = await bot.getUser(Snowflake(dbValues['user_id']));
  int availableCookies = dbValues['available_cookies'];
  int level = dbValues['level'];

  var statsEmbed = EmbedBuilder()
    ..addField(name: "Available Cookies", content: availableCookies, inline: true)
    ..addField(name: "Level (WIP)", content: level, inline: true);
  statsEmbed.color = DiscordColor.fromHexString("87CEEB");
  statsEmbed.thumbnailUrl = member.avatarURL(format: "png", size: 512);
  statsEmbed.timestamp = DateTime.now().toUtc();
  statsEmbed.title = "Stats for ${member.username}#${member.discriminator}";

  ctx.reply(embed: statsEmbed);
}
