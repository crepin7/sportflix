import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tigoals_match.dart';
import '../services/tigoals_service.dart';
import '../theme.dart';
import 'tigoals_player_screen.dart';

class TigoalsScreen extends StatefulWidget {
  const TigoalsScreen({super.key});
  @override
  State<TigoalsScreen> createState() => _TigoalsScreenState();
}

class _TigoalsScreenState extends State<TigoalsScreen> {
  final _service = TigoalsService.instance;
  List<TigoalsMatch> _all = [];
  bool _loading = true;
  String? _error;
  String _filter = 'live';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _service.fetchLiveMatches();
      setState(() { _all = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<TigoalsMatch> get _filtered {
    if (_filter == 'live') {
      final live = _service.filterLive(_all);
      if (live.isEmpty) return _all.where((m) => m.channelIds.isNotEmpty).toList();
      return live;
    }
    if (_filter == 'upcoming') return _service.filterUpcoming(_all);
    return _all..sort((a,b) => a.matchTimeT.compareTo(b.matchTimeT));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _filterBar(),
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
              Text('Matchs du jour', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _filterBar() {
    Widget chip(String id, String label, IconData icon) {
      final sel = _filter == id;
      return ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: sel ? Colors.black : Colors.white), const SizedBox(width: 6), Text(label)]),
        selected: sel,
        onSelected: (_) => setState(() => _filter = id),
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surfaceLight,
        labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 12),
      );
    }
    final liveCount = _service.filterLive(_all).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        chip('live', 'En direct ${liveCount>0?"($liveCount)":""}', Icons.circle),
        const SizedBox(width: 8),
        chip('upcoming', 'À venir', Icons.schedule),
        const SizedBox(width: 8),
        chip('all', 'Tous', Icons.list),
      ]),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, color: Colors.redAccent, size: 36), const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black), child: const Text('Réessayer'))])));
    final list = _filtered;
    if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sports_soccer, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)), const SizedBox(height: 12), const Text('Aucun match pour le moment', style: TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 8), const Text('Reviens un peu plus tard', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)), const SizedBox(height: 16), OutlinedButton(onPressed: _load, child: const Text('Actualiser'))]));
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_,__) => const SizedBox(height: 10),
        itemBuilder: (c,i) => _matchCard(list[i]),
      ),
    );
  }

  Widget _matchCard(TigoalsMatch m) {
    final isLive = m.isLive;
    final date = m.matchDate;
    final timeStr = DateFormat('dd/MM HH:mm').format(date);
    final scoreStr = (m.homeScore != 0 || m.awayScore != 0 || isLive) ? '${m.homeScore} - ${m.awayScore}' : 'vs';
    final hasStream = m.channelIds.isNotEmpty || m.hasChannel;
    return InkWell(
      onTap: hasStream ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TigoalsPlayerScreen(match: m))) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isLive && hasStream ? AppTheme.primary.withValues(alpha: 0.6) : AppTheme.surfaceLight),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)), child: Row(children: [
                if (m.leagueLogo.isNotEmpty) Image.network(m.leagueLogo.replaceFirst('http://','https://'), width: 16, height: 16, errorBuilder: (_,__,___)=> const SizedBox()),
                const SizedBox(width: 6),
                Text(m.leagueEn, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ])),
              const Spacer(),
              if (isLive && hasStream) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('DIRECT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))])),
              const SizedBox(width: 6),
              Text(timeStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _team(m.homeName, m.homeLogoUrl, true)),
              Column(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)), child: Text(scoreStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                const SizedBox(height: 4),
                Text(hasStream ? '' : '', style: const TextStyle(color: Colors.transparent, fontSize: 1)),
              ]),
              Expanded(child: _team(m.awayName, m.awayLogoUrl, false)),
            ]),
            if (hasStream) ...[
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TigoalsPlayerScreen(match: m))), icon: const Icon(Icons.play_arrow, size: 18), label: Text(isLive ? 'Regarder' : 'Voir le match'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _team(String name, String logo, bool isHome) {
    final isWin007 = logo.contains('zq.win007.com') || logo.contains('win007.com');
    final img = isWin007 ? '' : (logo.startsWith('http://') ? logo.replaceFirst('http://', 'https://') : logo);
    return Column(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: isWin007 ? AppTheme.primary.withValues(alpha: 0.3) : Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white12)),
        child: ClipOval(
          child: isWin007
              ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)))
              : Image.network(img, fit: BoxFit.contain, errorBuilder: (_,__,___)=> Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.black26, fontWeight: FontWeight.bold)))),
        ),
      ),
      const SizedBox(height: 6),
      Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}
