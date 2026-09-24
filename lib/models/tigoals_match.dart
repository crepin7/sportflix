class TigoalsMatch {
  final int matchId;
  final int leagueId;
  final String leagueEn;
  final String homeName;
  final String awayName;
  final String homeId;
  final String awayId;
  final String homeLogoUrl;
  final String awayLogoUrl;
  final String leagueLogo;
  final String teamLink;
  final int matchTimeT;
  final int state; // 0 not started, 1 live, 2 finished?
  final int homeScore;
  final int awayScore;
  final int homeHalfScore;
  final int awayHalfScore;
  final bool hasChannel;
  final List<String> channelIds;
  final String countryCode;

  TigoalsMatch({
    required this.matchId,
    required this.leagueId,
    required this.leagueEn,
    required this.homeName,
    required this.awayName,
    required this.homeId,
    required this.awayId,
    required this.homeLogoUrl,
    required this.awayLogoUrl,
    required this.leagueLogo,
    required this.teamLink,
    required this.matchTimeT,
    required this.state,
    required this.homeScore,
    required this.awayScore,
    required this.homeHalfScore,
    required this.awayHalfScore,
    required this.hasChannel,
    required this.channelIds,
    required this.countryCode,
  });

  factory TigoalsMatch.fromJson(Map<String, dynamic> j, {List<String> channelIds = const []}) {
    return TigoalsMatch(
      matchId: j['matchId'] as int,
      leagueId: j['leagueId'] as int,
      leagueEn: j['leagueEn'] ?? '',
      homeName: j['homeName'] ?? '',
      awayName: j['awayName'] ?? '',
      homeId: j['homeId']?.toString() ?? '',
      awayId: j['awayId']?.toString() ?? '',
      homeLogoUrl: j['homeLogoUrl'] ?? '',
      awayLogoUrl: j['awayLogoUrl'] ?? '',
      leagueLogo: j['leagueLogo'] ?? '',
      teamLink: j['teamLink'] ?? '',
      matchTimeT: j['matchTime_t'] ?? 0,
      state: j['state'] ?? 0,
      homeScore: j['homeScore'] ?? 0,
      awayScore: j['awayScore'] ?? 0,
      homeHalfScore: j['homeHalfScore'] ?? 0,
      awayHalfScore: j['awayHalfScore'] ?? 0,
      hasChannel: j['hasChannel'] ?? false,
      channelIds: channelIds,
      countryCode: j['countryCode'] ?? '',
    );
  }

  DateTime get matchDate => DateTime.fromMillisecondsSinceEpoch(matchTimeT);

  bool get isLive => state == 1;
  bool get isFinished => state == 2 || state == 3;

  String get detailUrl => 'https://play33.tigoals236.com/football/$matchId-$teamLink.html';
}
