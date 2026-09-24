import 'package:flutter/material.dart';
import '../services/live_sports_service.dart';
import '../theme.dart';
import 'live_player_screen.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final _service = LiveSportsService.instance;
  List<LiveMatch> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _service.fetchAll();
      setState(() { _all = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      color: AppTheme.background,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.live_tv, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('En direct', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Scores • flux générique', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, color: Colors.redAccent, size: 36), const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black), child: const Text('Réessayer'))])));
    if (_all.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sports_soccer, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)), const SizedBox(height: 12), const Text('Aucun match à venir', style: TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 16), OutlinedButton(onPressed: _load, child: const Text('Actualiser'))]));
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _all.length,
        separatorBuilder: (_,__) => const SizedBox(height: 10),
        itemBuilder: (c,i) => _matchCard(_all[i]),
      ),
    );
  }

  Widget _matchCard(LiveMatch m) {
    final isLive = m.status.toLowerCase().contains('live') || m.status == '1H' || m.status == '2H';
    final score = (m.homeScore.isNotEmpty || m.awayScore.isNotEmpty) ? '${m.homeScore} - ${m.awayScore}' : 'vs';
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LivePlayerScreen(match: m))),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isLive ? AppTheme.primary.withValues(alpha: 0.6) : AppTheme.surfaceLight),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)), child: Row(children: [
                if (m.leagueBadge.isNotEmpty) Image.network(m.leagueBadge, width: 16, height: 16, errorBuilder: (_,__,___)=> const SizedBox()),
                const SizedBox(width: 6),
                Text(m.league, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ])),
              const Spacer(),
              if (isLive) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('DIRECT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))])),
              const SizedBox(width: 6),
              Text('${m.dateStr} ${m.timeStr}'.trim(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _team(m.home, m.homeBadge, true)),
              Column(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)), child: Text(score, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                const SizedBox(height: 4),
                Text(isLive ? 'En cours' : 'À venir', style: TextStyle(color: isLive ? AppTheme.primary : Colors.white24, fontSize: 10)),
              ]),
              Expanded(child: _team(m.away, m.awayBadge, false)),
            ]),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LivePlayerScreen(match: m))), icon: const Icon(Icons.play_arrow, size: 18), label: Text(isLive ? 'Regarder (flux générique)' : 'Flux générique'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)))),
          ],
        ),
      ),
    );
  }

  Widget _team(String name, String badge, bool isHome) {
    return Column(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white12)), child: ClipOval(child: badge.isEmpty ? const Icon(Icons.shield, color: Colors.black26) : Image.network(badge, fit: BoxFit.contain, errorBuilder: (_,__,___)=> const Icon(Icons.shield, color: Colors.black26)))),
      const SizedBox(height: 6),
      Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}
