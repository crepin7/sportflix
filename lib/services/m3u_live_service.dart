import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Un flux réel extrait d'une playlist M3U publique (ex: doms9/iptv Live Events).
/// Contient les headers exigés par l'hébergeur (Referer / User-Agent),
/// sans lesquels le flux répond 403.
class RealStream {
  final String url;
  final String label;
  final String referer;
  final String userAgent;
  final String logo;

  const RealStream({
    required this.url,
    required this.label,
    this.referer = '',
    this.userAgent = '',
    this.logo = '',
  });

  Map<String, String> get headers {
    final h = <String, String>{
      'User-Agent': userAgent.isNotEmpty
          ? userAgent
          : 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36',
    };
    if (referer.isNotEmpty) {
      h['Referer'] = referer;
      h['Origin'] = Uri.tryParse(referer)?.origin ?? referer;
    }
    return h;
  }
}

/// Un événement live M3U : 1 match + N variantes de flux (sources/qualités).
class M3uLiveEvent {
  final String competition;
  final String teamA;
  final String teamB;
  final String logo;
  final List<RealStream> streams;

  M3uLiveEvent({
    required this.competition,
    required this.teamA,
    required this.teamB,
    this.logo = '',
    List<RealStream>? streams,
  }) : streams = streams ?? [];
}

/// Parser + cache des playlists d'événements live (actualisées côté source
/// toutes les heures). TTL cache 10 min pour ne pas spammer.
class M3uLiveService {
  static final M3uLiveService instance = M3uLiveService._();
  M3uLiveService._();

  static const _primary =
      'https://s.id/d9Live'; // doms9/iptv Live Events (redirect)
  static const _fallback =
      'https://raw.githubusercontent.com/doms9/iptv/refs/heads/default/M3U8/events.m3u8';

  /// Sur web, on passe par le proxy Vercel (même origine, pas de CORS).
  static List<String> get _playlistUrls =>
      kIsWeb ? ['/api/live.m3u8'] : [_primary, _fallback];

  static const _defaultUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36';

  List<M3uLiveEvent>? _cache;
  DateTime? _cacheAt;
  static const _ttl = Duration(minutes: 10);

  /// Résultats de sonde par URL (vivant/mort + heure) pour ne pas retester
  /// à chaque refresh. TTL identique au cache playlist.
  final Map<String, (bool, DateTime)> _probeCache = {};

  /// Teste si un flux répond vraiment (200 + playlist). Avec les headers
  /// du flux (Referer/UA) sinon 403 assuré. Timeout court.
  Future<bool> probeStream(RealStream s) async {
    final cached = _probeCache[s.url];
    if (cached != null &&
        DateTime.now().difference(cached.$2) < _ttl) {
      return cached.$1;
    }
    var alive = false;
    try {
      final r = await http
          .get(Uri.parse(s.url), headers: s.headers)
          .timeout(const Duration(seconds: 4));
      alive = r.statusCode == 200 &&
          r.body.isNotEmpty &&
          r.body.contains('#EXTM3U');
    } catch (_) {
      alive = false;
    }
    _probeCache[s.url] = (alive, DateTime.now());
    return alive;
  }

  /// Titres hors-foot : on ne garde que le foot (soccer).
  static bool _isFootball(String title) {
    final t = title.toLowerCase();
    if (!t.contains(' vs ') && !t.contains(' vs. ')) return false;
    const denylist = [
      'afl', 'aussie rules', 'baseball', 'american football', 'nfl',
      'mlb', 'atp', 'wta', 'tennis', 'basketball', 'wnbl', 'nba',
      'volleyball', 'handball', 'cricket', 'rugby', 'hockey', 'golf',
      'darts', 'snooker', 'boxing', 'mma', 'ufc', 'motogp', 'f1 ',
      'formula 1', 'cycling', 'esports',
    ];
    for (final b in denylist) {
      if (t.contains(b)) return false;
    }
    return true;
  }

  Future<List<M3uLiveEvent>> fetchLiveEvents(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _ttl) {
      return _cache!;
    }
    String? body;
    // Navigateurs : User-Agent interdit (forbidden header) -> sans headers.
    final headers =
        kIsWeb ? <String, String>{} : {'User-Agent': _defaultUa};
    for (final url in _playlistUrls) {
      try {
        final r = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));
        if (r.statusCode == 200 && r.body.contains('#EXTINF')) {
          body = r.body;
          break;
        }
      } catch (_) {}
    }
    if (body == null) return _cache ?? [];
    final events = _parse(body);
    _cache = events;
    _cacheAt = DateTime.now();
    return events;
  }

  List<M3uLiveEvent> _parse(String body) {
    final byMatch = <String, M3uLiveEvent>{};
    String logo = '';
    String referer = '';
    String ua = '';
    String extinf = '';

    for (final raw in body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#EXTINF')) {
        extinf = line;
        logo = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line)?.group(1) ?? '';
        referer = '';
        ua = '';
      } else if (line.startsWith('#EXTVLCOPT:http-referrer=')) {
        referer = line.substring('#EXTVLCOPT:http-referrer='.length).trim();
      } else if (line.startsWith('#EXTVLCOPT:http-user-agent=')) {
        ua = line.substring('#EXTVLCOPT:http-user-agent='.length).trim();
      } else if (line.startsWith('#')) {
        continue; // autres tags (EXTM3U, etc.)
      } else if (extinf.isNotEmpty && (line.startsWith('http'))) {
        // ligne URL -> clôture une entrée
        final title = extinf.contains(',')
            ? extinf.substring(extinf.lastIndexOf(',') + 1).trim()
            : '';
        extinf = '';
        if (!_isFootball(title)) continue;
        final parsed = _parseTitle(title);
        if (parsed == null) continue;
        final key =
            '${_norm(parsed.$2)} vs ${_norm(parsed.$3)}';
        final stream = RealStream(
          url: line,
          label: parsed.$4.isNotEmpty ? parsed.$4 : 'Flux direct',
          referer: referer,
          userAgent: ua.isNotEmpty ? ua : _defaultUa,
          logo: logo,
        );
        final existing = byMatch[key];
        if (existing == null) {
          byMatch[key] = M3uLiveEvent(
            competition: parsed.$1,
            teamA: parsed.$2,
            teamB: parsed.$3,
            logo: logo,
            streams: [stream],
          );
        } else {
          existing.streams.add(stream);
        }
      }
    }
    return byMatch.values.toList();
  }

  /// "[Competition] Team A vs Team B | Source (Provider)" ->
  /// (competition, teamA, teamB, sourceLabel)
  (String, String, String, String)? _parseTitle(String title) {
    var rest = title;
    var competition = '';
    final compMatch = RegExp(r'^\[([^\]]+)\]\s*').firstMatch(rest);
    if (compMatch != null) {
      competition = compMatch.group(1)!.trim();
      rest = rest.substring(compMatch.end).trim();
    }
    var source = '';
    final pipeIdx = rest.indexOf('|');
    if (pipeIdx != -1) {
      source = rest.substring(pipeIdx + 1).trim();
      rest = rest.substring(0, pipeIdx).trim();
    }
    // Retire les tags de source collés aux équipes : " (FAWA)", " (PLIBRE)",
    // " (STP)", " (TVF90 | beIN Ñ)"... En profiter pour fusionner les
    // doublons (même match, plusieurs sources) et nettoyer l'affichage.
    // Limité aux parenthèses courtes de fin (vrais noms d'équipes préservés).
    rest = rest.replaceAll(RegExp(r'\s*\([^()]{1,24}\)\s*$'), '');
    final vsMatch =
        RegExp(r'^(.*?)\s+vs\.?\s+(.*?)$', caseSensitive: false)
            .firstMatch(rest);
    if (vsMatch == null) return null;
    var a = vsMatch.group(1)!.trim();
    var b = vsMatch.group(2)!.trim();
    // nettoie "1"/"2" de doublons type "Namibia vs Congo 1"
    a = a.replaceAll(RegExp(r'\s+\d+$'), '').trim();
    b = b.replaceAll(RegExp(r'\s+\d+$'), '').trim();
    if (a.isEmpty || b.isEmpty) return null;
    return (competition, a, b, source);
  }

  static String _norm(String s) {
    var n = s.toLowerCase();
    const accents = {
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'à': 'a', 'â': 'a',
      'ä': 'a', 'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u',
      'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
    };
    accents.forEach((k, v) => n = n.replaceAll(k, v));
    n = n.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
    return n;
  }

  /// Score de correspondance entre un match TheSportsDB et un event M3U.
  /// Retourne le nombre de mots significatifs (>3 lettres) communs par équipe.
  static int matchScore(
      String home, String away, M3uLiveEvent e) {
    int scoreFor(String team, String side) {
      final words = _norm(team)
          .split(' ')
          .where((w) => w.length > 3)
          .toList();
      if (words.isEmpty) {
        // nom court (ex: PSG) : match exact
        return _norm(side).contains(_norm(team)) ? 1 : -10;
      }
      var s = 0;
      final sideNorm = _norm(side);
      for (final w in words) {
        if (sideNorm.contains(w)) {
          s += 2;
        } else {
          s -= 1;
        }
      }
      return s;
    }

    return scoreFor(home, e.teamA) + scoreFor(away, e.teamB);
  }
}
