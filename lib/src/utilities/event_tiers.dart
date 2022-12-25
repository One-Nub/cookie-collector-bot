import '../core/CCBot.dart';

import 'package:nyxx/nyxx.dart' show Cacheable, Snowflake, IMember, IRole;

const TierOneRole = 1053835787776577566; // Bronze
const TierTwoRole = 1053835841002283159; // Gold
const TierThreeRole = 1053835877752778833; // Diamond

const TieredGuildID = 1044788433412948058;

Future<int> getUserTier(int userID, {int? guildID, Iterable<Cacheable<Snowflake, IRole>>? roleList}) async {
  CCBot bot = CCBot();
  guildID ??= TieredGuildID;

  // Preemptively return 0 for guilds we don't want to have tiers in.
  if (guildID != TieredGuildID) return 0;

  if (roleList == null) {
    IMember member = await bot.gateway.httpEndpoints.fetchGuildMember(Snowflake(guildID), Snowflake(userID));
    roleList = member.roles;
  }

  int tierResult = 0;
  roleList.forEach((element) {
    if (element.id.id == TierOneRole) {
      tierResult = 1;
    } else if (element.id.id == TierTwoRole) {
      tierResult = 2;
    } else if (element.id.id == TierThreeRole) {
      tierResult = 3;
    }
  });

  return tierResult;
}
