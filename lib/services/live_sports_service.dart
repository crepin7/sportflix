import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  /// Priorité d'affichage de la compétition (0 = CL ... 50 = autres).
  final int leagueRank;
  /// État des vrais flux : 'unchecked' (pas encore testé), 'alive', 'dead'.
  final String streamState;

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
    int? leagueRank,
    this.streamState = 'unchecked',
  })  : streams = streams ?? const [],
        leagueRank = leagueRank ?? rankForLeague(league);

  bool get hasRealStream => streams.isNotEmpty;

  /// Vrai flux vérifié jouable (sonde HTTP passée).
  bool get isVerifiedLive =>
      streams.isNotEmpty && streamState == 'alive';

  /// Candidat à vérifier (sonde pas encore passée).
  bool get isPendingCheck =>
      streams.isNotEmpty && streamState == 'unchecked';

  bool get isLiveNow =>
      status == 'RÉEL' ||
      status.toLowerCase().contains('live') ||
      status == '1H' ||
      status == '2H';

  /// Headers HTTP compatibles web : les navigateurs interdisent de définir
  /// User-Agent (forbidden header) et lèvent une exception sinon.
  static Map<String, String> get _httpHeaders =>
      kIsWeb ? {} : {'User-Agent': 'Mozilla/5.0'};

  /// Rang d'affichage : grandes compétitions d'abord, œufs brouillés ensuite.
  static int rankForLeague(String league) {
    final l = league.toLowerCase();
    if (l.contains('champions league') &&
        !l.contains('europa') &&
        !l.contains('conference')) {
      return 0;
    }
    if (l.contains('europa league')) return 1;
    if (l.contains('premier league')) return 2;
    if (l.contains('la liga') || l.contains('laliga')) return 3;
    if (l.contains('serie a')) return 4;
    if (l.contains('bundesliga')) return 5;
    if (l.contains('ligue 1')) return 6;
    if (l.contains('conference league')) return 7;
    if (l.contains('copa') ||
        l.contains('fa cup') ||
        l.contains('coupe') ||
        l.contains('cup')) return 8;
    if (l.contains('nations league') ||
        l.contains('naciones') ||
        l.contains('nations')) return 9;
    if (l.contains('qualif') || l.contains('clasificaci')) return 10;
    return 50;
  }

  /// Tri d'affichage : flux vérifiés → candidats → grosses ligues → horaire.
  static int displayOrder(LiveMatch a, LiveMatch b) {
    int stateScore(LiveMatch m) {
      if (m.streamState == 'alive') return 2;
      if (m.streams.isNotEmpty && m.streamState == 'unchecked') return 1;
      return 0;
    }

    final r = stateScore(b).compareTo(stateScore(a));
    if (r != 0) return r;
    final l = a.leagueRank.compareTo(b.leagueRank);
    if (l != 0) return l;
    final s =
        (a.isLiveNow ? 0 : 1).compareTo(b.isLiveNow ? 0 : 1);
    if (s != 0) return s;
    final name = '${a.league}|${a.home}|${a.away}';
    final nameB = '${b.league}|${b.home}|${b.away}';
    final t =
        '${a.dateStr} ${a.timeStr}'.compareTo('${b.dateStr} ${b.timeStr}');
    if (t != 0) return t;
    return name.compareTo(nameB);
  }

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
        status: status,
        homeScore: homeScore,
        awayScore: awayScore,
        hlsUrl: s.first.url,
        streams: s,
        leagueRank: leagueRank,
        streamState: 'unchecked',
      );

  LiveMatch withStreamState(String state, [List<RealStream>? aliveOnly]) =>
      LiveMatch(
        id: id,
        league: league,
        home: home,
        away: away,
        homeBadge: homeBadge,
        awayBadge: awayBadge,
        leagueBadge: leagueBadge,
        dateStr: dateStr,
        timeStr: timeStr,
        status: status,
        homeScore: homeScore,
        awayScore: awayScore,
        hlsUrl: (aliveOnly != null && aliveOnly.isNotEmpty)
            ? aliveOnly.first.url
            : hlsUrl,
        streams: aliveOnly ?? streams,
        leagueRank: leagueRank,
        streamState: state,
      );

  LiveMatch withBadges(String homeB, String awayB) => LiveMatch(
        id: id,
        league: league,
        home: home,
        away: away,
        homeBadge: homeB.isNotEmpty ? homeB : homeBadge,
        awayBadge: awayB.isNotEmpty ? awayB : awayBadge,
        leagueBadge: leagueBadge,
        dateStr: dateStr,
        timeStr: timeStr,
        status: status,
        homeScore: homeScore,
        awayScore: awayScore,
        hlsUrl: hlsUrl,
        streams: streams,
        leagueRank: leagueRank,
        streamState: streamState,
      );

  bool get isM3uOnly => id.startsWith('m3u-');
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
        final r = await http.get(url, headers: LiveMatch._httpHeaders).timeout(const Duration(seconds: 8));
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
      final r = await http.get(Uri.parse('https://www.thesportsdb.com/api/v1/json/3/livescore.php?l=English_Premier_League'), headers: LiveMatch._httpHeaders).timeout(const Duration(seconds: 8));
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
      // Badges d'équipes remplis plus tard par TeamBadgeService (le logo
      // de l'event est celui de la compétition, pas des équipes).
      for (final e in live) {
        if (used.contains(e)) continue;
        all.insert(
          0,
          LiveMatch(
            id: 'm3u-${e.teamA.hashCode}-${e.teamB.hashCode}',
            league: e.competition.isNotEmpty
                ? e.competition
                : 'En direct',
            home: e.teamA,
            away: e.teamB,
            homeBadge: '',
            awayBadge: '',
            leagueBadge: e.logo,
            dateStr: "Aujourd'hui",
            timeStr: '',
            status: 'LIVE',
            homeScore: '',
            awayScore: '',
            hlsUrl: e.streams.first.url,
            streams: e.streams,
            streamState: 'unchecked',
          ),
        );
      }
      // Les vrais matchs d'abord, triés par compétition puis horaire.
      all.sort(LiveMatch.displayOrder);
    } catch (_) {}
    return all;
  }

  /// Sonde les vrais flux en arrière-plan : ne garde que les sources qui
  /// répondent 200 avec une playlist. Les rencontres M3U dont tous les flux
  /// sont morts sont retirées ; les horaires repassent en générique.
  /// Sur web : pas de CORS vers ces hébergeurs -> on ne sonde pas.
  Future<List<LiveMatch>> verifyRealStreams(List<LiveMatch> matches) async {
    if (kIsWeb) return matches;
    final m3u = M3uLiveService.instance;
    final out = <LiveMatch>[];
    // Par paquets pour ne pas inonder le réseau.
    for (var i = 0; i < matches.length; i += 8) {
      final chunk = matches.skip(i).take(8);
      final verified = await Future.wait(chunk.map((m) async {
        if (m.streams.isEmpty || m.streamState != 'unchecked') return m;
        final alive = <RealStream>[];
        final results = await Future.wait(
            m.streams.map((s) => m3u.probeStream(s)));
        for (var k = 0; k < m.streams.length; k++) {
          if (results[k]) alive.add(m.streams[k]);
        }
        if (alive.isEmpty) {
          if (m.isM3uOnly) return null; // rencontre fantôme -> masquée
          return m.withStreamState('dead', []);
        }
        return m.withStreamState('alive', alive);
      }));
      for (final m in verified) {
        if (m != null) out.add(m);
      }
    }
    out.sort(LiveMatch.displayOrder);
    return out;
  }
}
