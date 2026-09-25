import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml_events.dart';

/// Une émission du guide TV.
class EpgProgram {
  final String title;
  final String subTitle;
  final DateTime start;
  final DateTime stop;

  const EpgProgram({
    required this.title,
    required this.subTitle,
    required this.start,
    required this.stop,
  });

  Map<String, dynamic> toJson() => {
        't': title,
        's': subTitle,
        'start': start.millisecondsSinceEpoch,
        'stop': stop.millisecondsSinceEpoch,
      };

  factory EpgProgram.fromJson(Map<String, dynamic> j) => EpgProgram(
        title: j['t'] as String? ?? '',
        subTitle: j['s'] as String? ?? '',
        start: DateTime.fromMillisecondsSinceEpoch(j['start'] as int),
        stop: DateTime.fromMillisecondsSinceEpoch(j['stop'] as int),
      );

  /// Heuristique "c'est un match" : deux équipes séparées.
  bool get looksLikeMatch {
    final t = ' $title ';
    if (title.contains(' vs ') ||
        title.contains(' VS ') ||
        RegExp(r'\sv\s', caseSensitive: false).hasMatch(t)) {
      return true;
    }
    final sub = subTitle.toLowerCase();
    final leagueish = sub.contains('ligue') ||
        sub.contains('league') ||
        sub.contains('coupe') ||
        sub.contains('champions') ||
        sub.contains('cup');
    return leagueish && RegExp(r'\s-\s').hasMatch(title);
  }
}

/// Guide TV (XMLTV) : dit ce qui passe *en ce moment* sur les chaînes 24/7.
/// Sources : epgshare01 (BEIN 35Ko + FR ~5Mo), cache 12h en local.
class EpgService {
  static final EpgService instance = EpgService._();
  EpgService._();

  static const _sources = {
    'bein': 'https://epgshare01.online/epgshare01/epg_ripper_BEIN1.xml.gz',
    'fr': 'https://epgshare01.online/epgshare01/epg_ripper_FR1.xml.gz',
  };

  static const _prefsKey = 'epg_cache_v1';
  static const _ttl = Duration(hours: 12);

  /// epgId -> programmes triés par heure de début.
  final Map<String, List<EpgProgram>> _programs = {};
  bool _loaded = false;

  /// Télécharge (si cache expiré) et parse uniquement les [wanted]
  /// au format (source, epgId). Ne télécharge chaque fichier qu'une fois.
  Future<void> load(Set<(String, String)> wanted) async {
    if (wanted.isEmpty) return;
    await _restoreCache();
    final missing = <String, Set<String>>{};
    for (final (src, id) in wanted) {
      if (!_programs.containsKey(id)) {
        missing.putIfAbsent(src, () => <String>{}).add(id);
      }
    }
    if (missing.isEmpty) {
      _loaded = true;
      return;
    }
    var changed = false;
    for (final entry in missing.entries) {
      final url = _sources[entry.key];
      if (url == null) continue;
      try {
        final r = await http
            .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
            .timeout(const Duration(seconds: 60));
        if (r.statusCode != 200 || r.bodyBytes.isEmpty) continue;
        final parsed = _parseXmlTv(
          _gunzip(r.bodyBytes),
          entry.value,
        );
        for (final e in parsed.entries) {
          _programs[e.key] = e.value;
        }
        changed = true;
      } catch (_) {}
    }
    if (changed) await _saveCache();
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  /// (émission en cours, suivante) pour un epgId, heures locales.
  (EpgProgram?, EpgProgram?) programsFor(String epgId) {
    final list = _programs[epgId];
    if (list == null || list.isEmpty) return (null, null);
    final now = DateTime.now();
    EpgProgram? cur;
    EpgProgram? next;
    for (final p in list) {
      if (!p.start.isAfter(now) && p.stop.isAfter(now)) {
        cur = p;
      } else if (p.start.isAfter(now)) {
        next ??= p;
        if (cur != null) break;
      }
    }
    // Si rien en cours (trou dans la grille), next = premier à venir.
    next ??= list.cast<EpgProgram?>().firstWhere(
          (p) => p!.start.isAfter(now),
          orElse: () => null,
        );
    return (cur, next);
  }

  /// Les couches HTTP (dart:io autoUncompress, fetch navigateur) décompressent
  /// déjà le gzip : les bytes reçus sont du XML en clair.
  String _gunzip(List<int> bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Parse événementiel (faible mémoire) : ne garde que les [wanted].
  Map<String, List<EpgProgram>> _parseXmlTv(
      String text, Set<String> wanted) {
    final out = <String, List<EpgProgram>>{};
    String? channel;
    String? start;
    String? stop;
    String? title;
    String? sub;
    String? textFor; // 'title' | 'sub-title' | null

    for (final event in parseEvents(text)) {
      if (event is XmlStartElementEvent) {
        if (event.name == 'programme') {
          channel = null;
          start = null;
          stop = null;
          title = null;
          sub = null;
          for (final attr in event.attributes) {
            if (attr.name == 'channel') channel = attr.value;
            if (attr.name == 'start') start = attr.value;
            if (attr.name == 'stop') stop = attr.value;
          }
        } else if (event.name == 'title') {
          textFor = 'title';
        } else if (event.name == 'sub-title') {
          textFor = 'sub';
        } else {
          textFor = null;
        }
      } else if (event is XmlTextEvent) {
        final t = event.value.trim();
        if (t.isNotEmpty) {
          if (textFor == 'title') {
            title = '${title ?? ''} $t'.trim();
          } else if (textFor == 'sub') {
            sub = '${sub ?? ''} $t'.trim();
          }
        }
      } else if (event is XmlEndElementEvent) {
        if (event.name == 'programme') {
          if (channel != null &&
              wanted.contains(channel) &&
              start != null &&
              stop != null) {
            final s = _parseTime(start);
            final e = _parseTime(stop);
            if (s != null && e != null) {
              out.putIfAbsent(channel, () => []).add(EpgProgram(
                    title: _unescape(title ?? ''),
                    subTitle: _unescape(sub ?? ''),
                    start: s,
                    stop: e,
                  ));
            }
          }
          channel = null;
        }
        textFor = null;
      }
    }
    for (final list in out.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    return out;
  }

  /// "20260922004800 +0100" -> DateTime local.
  DateTime? _parseTime(String v) {
    try {
      final m = RegExp(
              r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\s*([+-])(\d{2})(\d{2})')
          .firstMatch(v.trim());
      if (m == null) return null;
      final dt = DateTime.utc(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
      );
      var offsetMinutes =
          int.parse(m.group(8)!) * 60 + int.parse(m.group(9)!);
      if (m.group(7) == '-') offsetMinutes = -offsetMinutes;
      return dt.subtract(Duration(minutes: offsetMinutes)).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _unescape(String s) =>
      s.replaceAll('&amp;', '&').replaceAll('&apos;', "'").replaceAll('&quot;', '"');

  Future<void> _restoreCache() async {
    if (_programs.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.fromMillisecondsSinceEpoch(j['at'] as int);
      if (DateTime.now().difference(at) > _ttl) return;
      final progs = j['programs'] as Map<String, dynamic>;
      for (final e in progs.entries) {
        _programs[e.key] = (e.value as List)
            .map((p) => EpgProgram.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'at': DateTime.now().millisecondsSinceEpoch,
          'programs': _programs.map(
            (k, v) => MapEntry(k, v.map((p) => p.toJson()).toList()),
          ),
        }),
      );
    } catch (_) {}
  }
}
