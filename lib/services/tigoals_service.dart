import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tigoals_match.dart';

class TigoalsService {
  static final TigoalsService instance = TigoalsService._();
  TigoalsService._();

  static const _host = 'play33.tigoals236.com';
  static const _dapi = 'https://dapiab.aifvfjuf56juh.cfd';
  static const _cfapiGate = 'https://cfapi.aifvfjuf56juh.cfd/gatebce4b9ba6fe6fb0db249c3e31c';

  Map<String, String> get _headers => {
    'Referer': 'https://$_host/livestream.html',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0 Safari/537.36',
    'Accept': 'application/json',
  };

  Future<List<TigoalsMatch>> fetchLiveMatches() async {
    final t = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_dapi/api/merge/schedules?lang=1&d=$_host&_t=$t');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) throw Exception('schedules ${res.statusCode}');
    final data = jsonDecode(res.body);
    final List list = (data is Map ? (data['matchList'] ?? data['data']?['matchList'] ?? []) : []) as List;
    // get channel mapping
    final channelMap = await _fetchChannelMap();
    final matches = list.map((e) {
      final m = e as Map<String, dynamic>;
      final id = m['matchId'] as int;
      final ch = channelMap[id] ?? [];
      return TigoalsMatch.fromJson(m, channelIds: ch);
    }).toList();
    // enrich hasChannel based on map if missing
    return matches.cast<TigoalsMatch>().toList();
  }

  Future<Map<int, List<String>>> _fetchChannelMap() async {
    try {
      final t = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.parse('$_cfapiGate/api/merge/getMatchChannels?d=$_host&_t=$t');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode != 200) return {};
      final List data = jsonDecode(res.body) as List;
      final map = <int, List<String>>{};
      for (final e in data) {
        final m = e as Map<String, dynamic>;
        final id = m['matchId'] as int;
        final ids = (m['channelIds']?.toString() ?? '').split(',').where((s) => s.isNotEmpty).toList();
        if (ids.isNotEmpty) map[id] = ids;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  List<TigoalsMatch> filterLive(List<TigoalsMatch> all) => all.where((m) => m.hasChannel || m.isLive || m.channelIds.isNotEmpty).toList();

  List<TigoalsMatch> filterUpcoming(List<TigoalsMatch> all) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return all.where((m) => m.matchTimeT > now - 2 * 3600 * 1000).toList()
      ..sort((a,b) => a.matchTimeT.compareTo(b.matchTimeT));
  }
}
