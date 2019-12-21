part of commands;

class SayParameterProcessor implements Preprocessor{
  const SayParameterProcessor();
  
  @override
  Future<PreprocessorResult> execute(List<Object> services, Message message) 
  async {
    RegExp idFinder = RegExp("\\d+[^>]"); //Gets only the numbers in the ID
    Match idMatch = idFinder.firstMatch(message.content); 
    if (idMatch == null) {
      Message msg = await message.reply(content: "I need a channel to send to");
      await Future.delayed(Duration(seconds: 3));
      msg.delete();
      return PreprocessorResult.error("No channel ID found");
    }
    
    String id = idMatch.group(0); //Since an ID was found, get it
    TextChannel channel = message.guild.channels[Snowflake(id)];
    if(channel == null) {
      Message msg = await message.reply(content: "That wasn't a channel you hooligan");
      await Future.delayed(Duration(seconds: 3));
      msg.delete();
      return PreprocessorResult.error("Non-channel ID given");
    }
    
    return PreprocessorResult.success();
  }
}

@SayParameterProcessor()
@Restrict(requiredContext: ContextType.guild, admin: true)
@Command("say")
Future<void> say(CommandContext ctx, TextChannel channel, @Remainder() String rest) async {
  if(rest == "")
    await ctx.replyTemp(Duration(seconds: 3), 
      content: "Somehow you forgot to tell me what to say! Try again");
  else
    await channel.send(content: rest);
}
