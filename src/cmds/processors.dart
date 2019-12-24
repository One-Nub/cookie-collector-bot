part of commands;

/*Preprocessors*/
//Typically for parameter verification

//Confirms that a TextChannel is in a message sent by a user
class TextChannelProcessor implements Preprocessor{
  const TextChannelProcessor();
  
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

class UserProcessor implements Preprocessor{
  const UserProcessor();
  
  @override
  Future<PreprocessorResult> execute(List<Object> services, Message message) 
  async {
    RegExp idFinder = RegExp("\\d+[^>]"); //Gets only the numbers in the ID
    Match idMatch = idFinder.firstMatch(message.content);
    String mentionError = "I need a user mention as a parameter!";
    if (idMatch == null) {
      await message.reply(content: mentionError);
      return PreprocessorResult.error("No user ID found");
    }
    
    String id = idMatch.group(0); //Since an ID was found, get it
    Member guildMember = message.guild.members[Snowflake(id)];
    if(guildMember == null) {
      await message.reply(content: mentionError);
      return PreprocessorResult.error("Non-user ID given");
    }
    
    return PreprocessorResult.success();
  }
}