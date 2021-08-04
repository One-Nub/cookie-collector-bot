import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commander/commander.dart';

import 'Argument.dart';
import '../exceptions/GuildContextRequired.dart';
import '../exceptions/InvalidChannelException.dart';
import '../exceptions/MissingArgumentException.dart';


/// Facilitates the ability of getting a Channel from a passed input.
///
/// Accepted types: TextGuildChannel, VoiceGuildChannel, CategoryGuildChannel
/// Throws [GuildContextRequiredException] when run from a non-guild context.
/// Throws [MissingArgumentException] if an argument cannot be found.
/// Throws [InvalidChannelException] if a valid channel cannot be found.
class ChannelArgument<T extends GuildChannel> extends Argument {
  late bool searchChannelNames;

  ChannelArgument(
      {bool pipeDelimiter = false,
      this.searchChannelNames = false,
      bool isRequired = false})
      : super(pipeDelimiter, isRequired);

  @override
  Future<T> parseArg(CommandContext ctx, String message) async {
    if (ctx.guild == null) {
      throw GuildContextRequiredException();
    }

    //Remove leading space and then the content used to run the command
    message = message.replaceFirst(" ", "");
    message = message.replaceFirst(ctx.commandMatcher, "");
    if(message == "") {
      throw MissingArgumentException();
    }

    message = message.trim();
    int channelID = 0;

    //Parse content if the message should have a pipe delimiter
    if (pipeDelimiterExpected && message.contains("|")) {
      message = message.split("|").first.trim();
    } else {
      //Text channels can't have spaces while categories & voice channels can.
      if (T == TextGuildChannel)
        message = message.split(RegExp("\\s+")).first.trim();
    }

    //Actions to set id. If there's no Regex match for an ID & searching channel names
    if (!rawIDRegex.hasMatch(message) && searchChannelNames) {
      List<T> typedChannelList = ctx.guild!.channels.whereType<T>().toList();
      for(T channel in typedChannelList) {
        if (channel.name.toLowerCase() == message.toLowerCase()) {
          channelID = channel.id.id;
          break;
        }
      }
    } else {
      channelID = parseIDHelper(message) ?? 0;
    }


    var guildChannels = ctx.guild!.channels.toList();
    List<Snowflake> guildChannelIDList = [];

    //Get a list of the IDs of the channels in the guild
    for(int inc = 0; inc < guildChannels.length; inc++) {
      guildChannelIDList.add(guildChannels[inc].id);
    }

    //ID wasn't updated/couldn't be found, or guild does not have a matching channel id.
    if (channelID == 0 || !guildChannelIDList.contains(channelID)) {
      throw InvalidChannelException("A matching channel could not be found within the guild.");
    }

    //Since by now the channel exists, get the first channel that matches the found channel ID.
    var returnChannel = guildChannels.firstWhere((element) { return element.id == channelID; });
    if(returnChannel.runtimeType != T) {
      throw InvalidChannelException("A channel was found, but it's type "
        "does not match the expected type.");
    }
    return returnChannel as T;
  }
}
