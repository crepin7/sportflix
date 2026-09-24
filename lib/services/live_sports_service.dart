import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveMatch {
  final String id;
  final String league;
  final String home;
  final String away;
  final String homeBadge;
  final String awayBadge;
  final String leagueBadge;
  final String dateStr;
  final String timeStr;
  final String status;
  final String homeScore;
  final String awayScore;
  final String hlsUrl;

  LiveMatch({
    required this.id,
    required this.league,
    required this.home,
    required this.away,
    required this.homeBadge,
    required this.awayBadge,
    required this.leagueBadge,
    required this.dateStr,
    required this.timeStr,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.hlsUrl,
  });
}

class LiveSportsService {
  static final LiveSportsService instance = LiveSportsService._();
  LiveSportsService._();

  // Grands championnats TheSportsDB (key 3 = test, pas besoin de clé perso)
  // IDs vérifiés: 4328=PL, 4335=LaLiga, 4332=SerieA, 4331=Bundesliga, 4334=Ligue1, 4480=CL, 4481=Europa
  static const _leagues = {
    '4328': 'Premier League',
    '4335': 'La Liga',
    '4332': 'Serie A',
    '4331': 'Bundesliga',
    '4334': 'Ligue 1',
    '4480': 'Champions League',
    '4481': 'Europa League',
  };

  // Mapping ligue -> HLS stable déjà vérifié 200 (151.80 / 99.27 / amagi)
  static const _hlsForLeague = {
    '4328': 'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
    '4335': 'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
    '4332': 'http://151.80.18.177:86/Canal+_cinema_HD/index.m3u8',
    '4331': 'http://151.80.18.177:86/W9_HD/index.m3u8',
    '4334': 'http://151.80.18.177:86/Canal+_sport_HD/index.m3u8',
    '4480': 'http://151.80.18.177:86/Canal+_sport_HD/index.m3u8',
    '4481': 'http://151.80.18.177:86/TMC/index.m3u8',
  };

  Future<List<LiveMatch>> fetchAll() async {
    final all = <LiveMatch>[];
    for (final entry in _leagues.entries) {
      try {
        final id = entry.key;
        final name = entry.value;
        // Next 5 events pour la ligue
        final url = Uri.parse('https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=$id');
        final r = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 8));
        if (r.statusCode != 200) continue;
        final j = jsonDecode(r.body);
        final List events = (j['events'] ?? []) as List;
        for (final e in events.take(4)) {
          final m = e as Map<String, dynamic>;
          all.add(LiveMatch(
            id: m['idEvent']?.toString() ?? m['id'].toString(),
            league: name,
            home: m['strHomeTeam'] ?? '?',
            away: m['strAwayTeam'] ?? '?',
            homeBadge: m['strHomeTeamBadge'] ?? '',
            awayBadge: m['strAwayTeamBadge'] ?? '',
            leagueBadge: m['strLeagueBadge'] ?? '',
            dateStr: m['dateEvent'] ?? '',
            timeStr: m['strTime'] ?? '',
            status: m['strStatus'] ?? 'Not Started',
            homeScore: m['intHomeScore']?.toString() ?? '',
            awayScore: m['intAwayScore']?.toString() ?? '',
            hlsUrl: _hlsForLeague[id] ?? 'http://151.80.18.177:86/Canal+_sport_HD/index.m3u8',
          ));
        }
      } catch (_) {}
    }
    // Aussi les lives du moment
    try {
      final r = await http.get(Uri.parse('https://www.thesportsdb.com/api/v1/json/3/livescore.php?l=English_Premier_League'), headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body);
        final List events = (j['events'] ?? []) as List;
        for (final e in events.take(4)) {
          final m = e as Map<String, dynamic>;
          all.insert(0, LiveMatch(
            id: m['idEvent']?.toString() ?? '',
            league: 'Premier League - LIVE',
            home: m['strHomeTeam'] ?? '?',
            away: m['strAwayTeam'] ?? '?',
            homeBadge: m['strHomeTeamBadge'] ?? '',
            awayBadge: m['strAwayTeamBadge'] ?? '',
            leagueBadge: m['strLeagueBadge'] ?? '',
            dateStr: m['dateEvent'] ?? '',
            timeStr: m['strTime'] ?? '',
            status: 'LIVE',
            homeScore: m['intHomeScore']?.toString() ?? '',
            awayScore: m['intAwayScore']?.toString() ?? '',
            hlsUrl: _hlsForLeague['4335']!,
          ));
        }
      }
    } catch (_) {}
    return all;
  }
}
