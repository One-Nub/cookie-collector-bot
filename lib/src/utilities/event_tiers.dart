import '../core/CCBot.dart';

import 'package:nyxx/nyxx.dart' show Snowflake, IMember;

const TierOneRole = 1052856548541595650;
const TierTwoRole = 1052856556020056124;
const TierThreeRole = 1053047515064307713;

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
