import 'dart:convert';
import 'package:http/http.dart' as http;
import 'm3u_live_service.dart';

export 'm3u_live_service.dart' show RealStream;

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
  /// Vrais flux du match (sources live M3U). Vide = horaire seul,
  /// le flux ouvert est alors le générique de repli [hlsUrl].
  final List<RealStream> streams;

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
    List<RealStream>? streams,
  }) : streams = streams ?? const [];

  bool get hasRealStream => streams.isNotEmpty;

  LiveMatch withRealStreams(List<RealStream> s) => LiveMatch(
        id: id,
        league: league,
        home: home,
        away: away,
        homeBadge: homeBadge,
        awayBadge: awayBadge,
        leagueBadge: leagueBadge,
        dateStr: dateStr,
        timeStr: timeStr,
        status: 'RÉEL',
        homeScore: homeScore,
        awayScore: awayScore,
        hlsUrl: s.first.url,
        streams: s,
      );
}

class LiveSportsService {
  static final LiveSportsService instance = LiveSportsService._();
  LiveSportsService._();

  // Scores et calendriers via TheSportsDB (clé test 3).
  // Les VRAIS flux viennent des playlists live M3U (doms9/iptv, actualisées
  // toutes les heures) : chaque event porte le nom des équipes + son HLS.
  // S'il n'y a pas de flux réel pour un match, [hlsUrl] générique sert
  // de repli et l'UI l'indique ("flux générique").
  static const _leagues = {
    '4328': 'Premier League',
    '4335': 'La Liga',
    '4332': 'Serie A',
    '4331': 'Bundesliga',
    '4334': 'Ligue 1',
    '4480': 'Champions League',
    '4481': 'Europa League',
  };

  // Mapping ligue -> flux générique stable (pas le match lui-même)
  static const _hlsForLeague = {
    '4328': 'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
    '4335': 'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
    '4332': 'http://151.80.18.177:86/Canal+_cinema_HD/index.m3u8',
    '4331': 'http://151.80.18.177:86/W9_HD/index.m3u8',
    '4334': 'http://151.80.18.177:86/Canal+_sport_HD/index.m3u8',
    '4480': 'http://151.80.18.177:86/Canal+_sport_HD/index.m3u8',
    '4481': 'http://151.80.18.177:86/TMC/index.m3u8',
  };

  Future<List<LiveMatch>> fetchAll({bool forceRefresh = false}) async {
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
            hlsUrl: _hlsForLeague['4328']!,
          ));
        }
      }
    } catch (_) {}
    // 2) Vrais flux live M3U : on les rattache aux matchs connus,
    //    et on ajoute les matchs non couverts par TheSportsDB.
    try {
      final live = await M3uLiveService.instance
          .fetchLiveEvents(forceRefresh: forceRefresh);
      final used = <M3uLiveEvent>{};
      for (var i = 0; i < all.length; i++) {
        M3uLiveEvent? best;
        var bestScore = 3; // seuil : les deux équipes reconnues
        for (final e in live) {
          if (used.contains(e)) continue;
          final s = M3uLiveService.matchScore(all[i].home, all[i].away, e);
          if (s > bestScore) {
            bestScore = s;
            best = e;
          }
        }
        if (best != null) {
          used.add(best);
          all[i] = all[i].withRealStreams(best.streams);
        }
      }
      // Events M3U sans équivalent TheSportsDB -> nouvelles cartes.
      for (final e in live) {
        if (used.contains(e)) continue;
        all.insert(
          0,
          LiveMatch(
            id: 'm3u-${e.teamA.hashCode}-${e.teamB.hashCode}',
            league: e.competition.isNotEmpty
                ? '${e.competition} • RÉEL'
                : 'En direct • RÉEL',
            home: e.teamA,
            away: e.teamB,
            homeBadge: e.logo,
            awayBadge: '',
            leagueBadge: e.logo,
            dateStr: "Aujourd'hui",
            timeStr: '',
            status: 'RÉEL',
            homeScore: '',
            awayScore: '',
            hlsUrl: e.streams.first.url,
            streams: e.streams,
          ),
        );
      }
      // Les vrais matchs d'abord.
      all.sort((a, b) {
        final r = (b.hasRealStream ? 1 : 0) - (a.hasRealStream ? 1 : 0);
        if (r != 0) return r;
        return 0;
      });
    } catch (_) {}
    return all;
  }
}
