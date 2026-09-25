import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'team_badge_seed.dart';

/// Logos des vraies équipes, quelle que soit l'équipe.
///
/// Astuce : la clé gratuite TheSportsDB ne renvoie PAS les blasons
/// (strTeamBadge vide), mais renvoie les IDs ESPN/API-Football, à partir
/// desquels on construit des URLs de logos CDN stables et vérifiées :
/// - ESPN : https://a.espncdn.com/i/teamlogos/soccer/500/{idESPN}.png
/// - API-Sports : https://media.api-sports.io/football/teams/{id}.png
///
/// Chaîne de résolution : cache 90j -> searchteams -> URL vérifiée (200 +
/// image). Seules les URLs vérifiées sont cachées/affichées.
class TeamBadgeService {
  static final TeamBadgeService instance = TeamBadgeService._();
  TeamBadgeService._();

  static const _prefsKey = 'team_badges_v1';
  static const _ttl = Duration(days: 90);

  final Map<String, (_Badge, DateTime)> _cache = {};
  bool _restored = false;

  /// Remplit les badges manquants pour [teamNames]. Retourne
  /// {nom normalisé: url du blason} pour les nouveaux trouvés.
  /// Concurrence limitée (API gratuite partagée).
  Future<Map<String, String>> enrich(Iterable<String> teamNames) async {
    await _restore();
    final wanted = <String, String>{}; // norm -> affichage
    for (final n in teamNames) {
      final norm = normName(n);
      if (norm.length < 3 ||
          kSeedTeamBadges.containsKey(norm) ||
          _fresh(norm) != null) {
        continue;
      }
      wanted[norm] = n;
    }
    final found = <String, String>{};
    // Par paquets de 3 pour ne pas se faire bloquer.
    final norms = wanted.keys.toList();
    for (var i = 0; i < norms.length; i += 3) {
      final chunk = norms.skip(i).take(3);
      final results = await Future.wait(chunk.map((norm) async {
        final url = await _searchBadge(wanted[norm]!);
        return MapEntry(norm, url);
      }));
      for (final e in results) {
        if (e.value.isNotEmpty) {
          _cache[e.key] = (_Badge(e.value), DateTime.now());
          found[e.key] = e.value;
        }
      }
    }
    if (found.isNotEmpty) await _save();
    return found;
  }

  /// Badge connu en cache (frais) ou dans le seed embarqué, '' sinon.
  /// Le seed (grands clubs, URLs vérifiées) répond instantanément.
  String cachedBadge(String teamName) {
    final seed = kSeedTeamBadges[normName(teamName)];
    if (seed != null && seed.isNotEmpty) return seed;
    return _fresh(normName(teamName)) ?? '';
  }

  String? _fresh(String norm) {
    final e = _cache[norm];
    if (e == null) return null;
    if (DateTime.now().difference(e.$2) > _ttl) {
      _cache.remove(norm);
      return null;
    }
    return e.$1.url.isNotEmpty ? e.$1.url : null;
  }

  Future<String> _searchBadge(String teamName) async {
    final candidates = await _searchCandidates(teamName);
    for (final url in candidates) {
      if (await _verifyImage(url)) return url;
    }
    return '';
  }

  /// URLs candidates par ordre de préférence (toutes à vérifier).
  Future<List<String>> _searchCandidates(String teamName) async {
    try {
      final q = Uri.encodeQueryComponent(teamName);
      final url = Uri.parse(
          'https://www.thesportsdb.com/api/v1/json/3/searchteams.php?t=$q');
      final r = await http
          .get(url, headers: kIsWeb ? const {} : {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return const [];
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final teams = (j['teams'] as List?) ?? [];
      if (teams.isEmpty) return const [];
      final want = normName(teamName);
      List<Map<String, dynamic>> ordered =
          teams.cast<Map<String, dynamic>>();
      // Mêmes préférences qu'avant : égalité exacte, puis inclusion.
      final exact = ordered
          .where((m) => normName(m['strTeam'] as String? ?? '') == want)
          .toList();
      final incl = ordered.where((m) {
        final cand = normName(m['strTeam'] as String? ?? '');
        return cand.contains(want) || want.contains(cand);
      }).toList();
      final rest = ordered
          .where((m) => !exact.contains(m) && !incl.contains(m))
          .toList();
      ordered = [...exact, ...incl, ...rest];
      final urls = <String>[];
      for (final m in ordered.take(3)) {
        final direct = (m['strTeamBadge'] as String?) ?? '';
        if (direct.isNotEmpty) urls.add(direct);
        final espn = m['idESPN']?.toString() ?? '';
        if (espn.isNotEmpty && espn != '0') {
          urls.add('https://a.espncdn.com/i/teamlogos/soccer/500/$espn.png');
        }
        final api = m['idAPIfootball']?.toString() ?? '';
        if (api.isNotEmpty && api != '0') {
          urls.add('https://media.api-sports.io/football/teams/$api.png');
        }
      }
      return urls;
    } catch (_) {
      return const [];
    }
  }

  /// Vérifie qu'une URL rend vraiment une image (pas un 404/placeholder).
  /// HEAD suffit (headers seuls, pas de téléchargement).
  Future<bool> _verifyImage(String url) async {
    final headers =
        kIsWeb ? const <String, String>{} : {'User-Agent': 'Mozilla/5.0'};
    try {
      final r = await http
          .head(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return false;
      final ct = r.headers['content-type'] ?? '';
      if (ct.startsWith('image/')) return true;
      // HEAD sans content-type : petit GET de contrôle.
      final g = await http
          .get(Uri.parse(url), headers: {
            ...headers,
            'Range': 'bytes=0-2047',
          })
          .timeout(const Duration(seconds: 6));
      if (g.statusCode != 200 && g.statusCode != 206) return false;
      final gct = g.headers['content-type'] ?? '';
      return gct.startsWith('image/') && g.bodyBytes.length >= 512;
    } catch (_) {
      return false;
    }
  }

  /// "Paris Saint-Germain" -> "paris saint germain".
  static String normName(String s) {
    var n = s.toLowerCase();
    const accents = {
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'à': 'a', 'â': 'a',
      'ä': 'a', 'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u',
      'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n', 'ß': 'ss', 'ø': 'o',
    };
    accents.forEach((k, v) => n = n.replaceAll(k, v));
    n = n.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
    return n;
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in j.entries) {
        final m = e.value as Map<String, dynamic>;
        _cache[e.key] = (
          _Badge(m['u'] as String? ?? ''),
          DateTime.fromMillisecondsSinceEpoch(m['at'] as int? ?? 0),
        );
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_cache.map((k, v) => MapEntry(k, {
              'u': v.$1.url,
              'at': v.$2.millisecondsSinceEpoch,
            }))),
      );
    } catch (_) {}
  }
}

class _Badge {
  final String url;
  const _Badge(this.url);
}
