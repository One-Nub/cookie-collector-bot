part of commands;

/*Preprocessors*/
//Typically for parameter verification
//Below the preprocessors is a helper cache for me to use

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

/*Helper class*/

//Primarily made to handle the scenario in which I want
//a cooldown for a command (because the built in cooldown
//-doesn't let me prompt a user saying they can't run the command
class UserBasedCache implements Cache<Snowflake, dynamic> {
  var _cache = Map<Snowflake, DateTime>();
  UserBasedCache() {
    _cache = Map();
  }
  
  /// Returns values of cache
  Iterable<dynamic> get values => _cache.values;

  /// Returns key's values of cache
  Iterable<Snowflake> get keys => _cache.keys;

  /// Find one element in cache
  DateTime findOne(bool predicate(dynamic item)) =>
      values.firstWhere(predicate, orElse: () => null);

  /// Find matching items based of [predicate]
  Iterable<DateTime> find(bool predicate(dynamic item)) => values.where(predicate);

  /// Returns element with key [key]
  DateTime operator [](Snowflake key) => _cache[key];

  /// Sets [item] for [key]
  void operator []=(Snowflake key, dynamic item) => _cache[key] = item;

  /// Puts [item] to collection if [key] doesn't exist in cache
  DateTime addIfAbsent(Snowflake key, dynamic item) {
    if (!_cache.containsKey(key)) return _cache[key] = item;
    return item;
  }

  /// Returns true if cache contains [key]
  bool hasKey(Snowflake key) => _cache.containsKey(key);

  /// Returns true if cache contains [value]
  bool hasValue(dynamic value) => _cache.containsValue(value);

  /// Clear cache
  void invalidate() => _cache.clear();

  /// Add to cache [value] associated with [key]
  void add(Snowflake key, dynamic value) => _cache[key] = value;

  /// Add [Map] to cache.
  void addMap(Map<Snowflake, dynamic> mp) => _cache.addAll(mp);

  /// Remove [key] with associated with it value
  void remove(Snowflake key) => _cache.remove(key);

  /// Remove everything where [predicate] is true
  void removeWhere(bool predicate(Snowflake key, dynamic value)) =>
      _cache.removeWhere(predicate);

  /// Loop over elements from cache
  void forEach(void f(Snowflake key, dynamic value)) => _cache.forEach(f);

  /// Take [count] elements from cache. Returns Iterable of cache values
  Iterable<dynamic> take(int count) => values.take(count);

  /// Takes [count] last elements from cache. Returns Iterable of cache values
  Iterable<dynamic> takeLast(int count) =>
      values.toList().sublist(values.length - count);

  /// Get first element
  dynamic get first => _cache.values.first;

  /// Get last element
  dynamic get last => _cache.values.last;

  /// Get number of elements from cache
  int get count => _cache.length;

  /// Returns cache as Map
  Map<Snowflake, dynamic> get asMap => this._cache;

  @override
  Future<void> dispose() => Future(() {
        this._cache.clear();
      });
}
