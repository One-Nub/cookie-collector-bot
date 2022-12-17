import '../core/CCBot.dart';

import 'package:nyxx/nyxx.dart' show Snowflake, IMember;

const TierOneRole = 1050547246204194867; // Bronze
const TierTwoRole = 1050547596298567680; // Gold
const TierThreeRole = 1050547709066621009; // Diamond

Future<int> getUserTier(int guildID, int userID) async {
  CCBot bot = CCBot();
  IMember member = await bot.gateway.httpEndpoints.fetchGuildMember(Snowflake(guildID), Snowflake(userID));

  int tierResult = 0;
  member.roles.forEach((element) {
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
