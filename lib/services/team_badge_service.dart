import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Logos des vraies équipes, quelle que soit l'équipe.
///
/// Chaîne de résolution (la première qui marche gagne) :
/// 1. cache local persistant (90 jours) — instantané, hors-ligne OK ;
/// 2. TheSportsDB `searchteams` (gratuit, CORS * donc OK sur web aussi).
///
/// Utilisé en 3e phase du chargement En direct : les cartes s'affichent
/// d'abord avec initiales, puis les vrais blasons arrivent au fil de l'eau.
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
      if (norm.length < 3 || _fresh(norm) != null) continue;
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

  /// Badge connu en cache (frais), '' sinon.
  String cachedBadge(String teamName) => _fresh(normName(teamName)) ?? '';

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
    try {
      final q = Uri.encodeQueryComponent(teamName);
      final url = Uri.parse(
          'https://www.thesportsdb.com/api/v1/json/3/searchteams.php?t=$q');
      final r = await http
          .get(url, headers: kIsWeb ? const {} : {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return '';
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final teams = (j['teams'] as List?) ?? [];
      if (teams.isEmpty) return '';
      final want = normName(teamName);
      // 1) égalité normalisée exacte.
      for (final t in teams) {
        final m = t as Map<String, dynamic>;
        final badge = (m['strTeamBadge'] as String?) ?? '';
        if (badge.isEmpty) continue;
        if (normName(m['strTeam'] as String? ?? '') == want) return badge;
      }
      // 2) inclusion (ex: "PSG" dans "Paris Saint-Germain").
      for (final t in teams) {
        final m = t as Map<String, dynamic>;
        final badge = (m['strTeamBadge'] as String?) ?? '';
        if (badge.isEmpty) continue;
        final cand = normName(m['strTeam'] as String? ?? '');
        if (cand.contains(want) || want.contains(cand)) return badge;
      }
      // 3) premier avec blason.
      for (final t in teams) {
        final badge =
            ((t as Map<String, dynamic>)['strTeamBadge'] as String?) ?? '';
        if (badge.isNotEmpty) return badge;
      }
    } catch (_) {}
    return '';
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
