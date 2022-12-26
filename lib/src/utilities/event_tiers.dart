import '../core/CCBot.dart';

import 'package:nyxx/nyxx.dart' show Cacheable, Snowflake, IMember, IRole;

const TierOneRole = 1054959782190137501; // Bronze
const TierTwoRole = 1054958659198791684; // Gold
const TierThreeRole = 1054956990926950402; // Diamond

const TieredGuildID = 918211605970423838;

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
