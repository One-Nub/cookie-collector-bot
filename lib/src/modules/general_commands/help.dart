import 'dart:collection';

import 'package:nyxx/nyxx.dart';
import 'package:onyx_chat/onyx_chat.dart';

import '../../core/CCBot.dart';

class HelpCommand extends TextCommand {
  @override
  String get name => "help";

  @override
  String get description => "Learn about the commands the bot has!";

  @override
  HashSet<String> get aliases => HashSet.from(["cmds", "commands"]);

  @override
  Future<void> commandEntry(TextCommandContext ctx, String message, List<String> args) async {
    CCBot bot = CCBot();

    EmbedBuilder cmdEmbed = EmbedBuilder()
      ..title = "Help Me!"
      ..timestamp = DateTime.now().toUtc()
      ..description = "Welcome to the commands list for Cookie Collector!";

    StringBuffer adminBuffer = StringBuffer();
    StringBuffer generalBuffer = StringBuffer();
    Iterator<TextCommand> commands = bot.onyxChat.commands.iterator;
    while (commands.moveNext()) {
      TextCommand currentCommand = commands.current;
      String cmdName = currentCommand.name;
      String cmdDescription = currentCommand.description!;
      if (currentCommand.name == "generate" || currentCommand.name == "say") {
        adminBuffer.writeln("`.${cmdName}` ➙ ${cmdDescription}");
      } else {
        generalBuffer.writeln("`.${cmdName}` ➙ ${cmdDescription}");
      }
    }

    cmdEmbed.addField(name: "Commands", content: generalBuffer.toString(), inline: false);
    if (bot.adminList.contains(ctx.author.id)) {
      cmdEmbed.addField(name: "Admin Commands", content: adminBuffer.toString(), inline: false);
    }

    IUser? authorUser = bot.gateway.users[ctx.author.id];
    if (authorUser == null) {
      authorUser = await bot.gateway.fetchUser(ctx.author.id);
    }
    IDMChannel authorDM = await authorUser.dmChannel;

    bool dmsOpen = true;
    await authorDM.sendMessage(MessageBuilder.embed(cmdEmbed)).catchError((onError) async {
      dmsOpen = false;
      return ctx.channel.sendMessage(MessageBuilder.embed(cmdEmbed)
        ..allowedMentions = (AllowedMentions()..allow(reply: false))
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
    });

    if (dmsOpen) {
      await ctx.channel.sendMessage(MessageBuilder.content("Please check your direct messages!")
        ..allowedMentions = (AllowedMentions()..allow(reply: false))
        ..replyBuilder = ReplyBuilder.fromMessage(ctx.message));
    }
  }
}
