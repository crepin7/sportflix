import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/live_sports_service.dart';
import '../services/team_badge_service.dart';
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
  bool _searchingLive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _searchingLive = false;
    });
    try {
      // Phase 1 : calendriers + candidats flux (rapide).
      final list = await _service.fetchAll(forceRefresh: force);
      if (!mounted) return;
      final sched =
          list.where((m) => m.streams.isEmpty).toList();
      final candidates =
          list.where((m) => m.streams.isNotEmpty).toList();
      if (kIsWeb) {
        // Pas de sonde possible sans CORS : on affiche tout de suite.
        setState(() {
          _all = list;
          _loading = false;
        });
        await _enrichBadges(list);
        return;
      }
      // On affiche d'abord les horaires, sans les candidats non vérifiés :
      // pas de cartes qui clignotent puis disparaissent.
      setState(() {
        _all = sched;
        _loading = false;
        _searchingLive = candidates.isNotEmpty;
      });
      // Phase 2 : blasons des horaires (cache + seed, rapide).
      await _enrichBadges(sched);
      if (!mounted) return;
      // Phase 3 : sonde des candidats en arrière-plan. Seuls les flux
      // vérifiés rejoignent la liste ; les morts sont écartés en silence.
      final verified = await _service.verifyRealStreams(candidates);
      if (!mounted) return;
      final merged = [...verified, ..._all]
        ..sort(LiveMatch.displayOrder);
      setState(() {
        _all = merged;
        _searchingLive = false;
      });
      // Phase 4 : blasons des directs vérifiés.
      await _enrichBadges(verified);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _searchingLive = false;
      });
    }
  }

  Future<void> _enrichBadges(List<LiveMatch> list) async {
    try {
      final missing = <String>{};
      for (final m in list) {
        if (!mounted) return;
        if (TeamBadgeService.instance.cachedBadge(m.home).isEmpty) {
          missing.add(m.home);
        }
        if (TeamBadgeService.instance.cachedBadge(m.away).isEmpty) {
          missing.add(m.away);
        }
        // La liste est triée (grosses ligues d'abord) : les 60 premiers
        // suffisent par ouverture, le cache fait converger la suite.
        if (missing.length >= 60) break;
      }
      if (missing.isEmpty) {
        _applyCachedBadges();
        return;
      }
      // Applique d'abord ce que le cache connaît déjà.
      _applyCachedBadges();
      // Puis va chercher le reste en ligne, par vagues.
      final found = await TeamBadgeService.instance.enrich(missing);
      if (!mounted || found.isEmpty) return;
      _applyCachedBadges();
    } catch (_) {}
  }

  void _applyCachedBadges() {
    if (!mounted) return;
    setState(() {
      _all = _all.map((m) {
        final hb = TeamBadgeService.instance.cachedBadge(m.home);
        final ab = TeamBadgeService.instance.cachedBadge(m.away);
        if (hb.isEmpty && ab.isEmpty) return m;
        return m.withBadges(hb, ab);
      }).toList();
    });
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
            decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.live_tv, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('En direct',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text(
                  _searchingLive
                      ? 'Recherche des directs…'
                      : 'Vrais matchs + scores',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ),
          if (_searchingLive && !_loading)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primary)),
            ),
          IconButton(
              onPressed: () => _load(force: true),
              icon: const Icon(Icons.refresh, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    if (_error != null)
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 36),
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () => _load(force: true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black),
                    child: const Text('Réessayer'))
              ])));
    if (_all.isEmpty)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.sports_soccer,
            size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text('Aucun match à venir',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        OutlinedButton(
            onPressed: () => _load(force: true),
            child: const Text('Actualiser'))
      ]));
    // Zone En direct TOUJOURS en premier : matchs vérifiés, ou squelettes
    // pendant la recherche (jamais un écran vide de génériques seuls).
    final live = _all
        .where((m) =>
            m.isVerifiedLive || (kIsWeb && m.isPendingCheck))
        .toList();
    final featured = _all
        .where((m) =>
            m.leagueRank <= 7 &&
            !m.isVerifiedLive &&
            !(kIsWeb && m.isPendingCheck))
        .toList();
    final sched = _all
        .where((m) =>
            m.leagueRank > 7 &&
            !m.isVerifiedLive &&
            !(kIsWeb && m.isPendingCheck))
        .toList();
    Widget section(String title, int count, Color color, IconData icon,
        List<LiveMatch> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, count, color, icon),
          const SizedBox(height: 10),
          for (final m in items) ...[
            _matchCard(m),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    final showSkeletons = _searchingLive && !kIsWeb;
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (live.isNotEmpty || showSkeletons)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('En direct', live.length,
                    Colors.greenAccent, Icons.live_tv,
                    searching: showSkeletons),
                const SizedBox(height: 10),
                for (final m in live) ...[
                  _matchCard(m),
                  const SizedBox(height: 10),
                ],
                if (showSkeletons && live.isEmpty) ...[
                  for (var i = 0; i < 3; i++) ...[
                    _skeletonCard(),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          if (featured.isNotEmpty)
            section("À l'affiche", featured.length, Colors.amber,
                Icons.emoji_events, featured),
          if (sched.isNotEmpty)
            section('Horaires', sched.length, AppTheme.textSecondary,
                Icons.schedule, sched),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count, Color color, IconData icon,
      {bool searching = false}) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(searching ? '…' : '$count',
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ),
      if (searching) ...[
        const SizedBox(width: 8),
        const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.greenAccent)),
      ],
    ]);
  }

  /// Carte d'attente pendant la recherche des directs.
  Widget _skeletonCard() {
    BoxDecoration box(Color c) => BoxDecoration(
        color: c, borderRadius: BorderRadius.circular(8));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 110, height: 18, decoration: box(AppTheme.surfaceLight)),
          const Spacer(),
          Container(width: 70, height: 18, decoration: box(AppTheme.surfaceLight)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: Column(children: [
            Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: AppTheme.surfaceLight, shape: BoxShape.circle)),
            const SizedBox(height: 6),
            Container(width: 70, height: 12, decoration: box(AppTheme.surfaceLight)),
          ])),
          Container(width: 60, height: 30, decoration: box(AppTheme.surfaceLight)),
          Expanded(
              child: Column(children: [
            Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: AppTheme.surfaceLight, shape: BoxShape.circle)),
            const SizedBox(height: 6),
            Container(width: 70, height: 12, decoration: box(AppTheme.surfaceLight)),
          ])),
        ]),
        const SizedBox(height: 10),
        Container(
            width: double.infinity,
            height: 40,
            decoration: box(AppTheme.surfaceLight)),
      ]),
    );
  }

  Widget _matchCard(LiveMatch m) {
    final isLive = m.status.toLowerCase().contains('live') ||
        m.status == '1H' ||
        m.status == '2H' ||
        m.status == 'RÉEL';
    final isReal = m.isVerifiedLive;
    final isPending = m.isPendingCheck;
    final score = (m.homeScore.isNotEmpty || m.awayScore.isNotEmpty)
        ? '${m.homeScore} - ${m.awayScore}'
        : 'vs';
    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => LivePlayerScreen(match: m))),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isReal
                  ? Colors.greenAccent.withValues(alpha: 0.7)
                  : isLive
                      ? AppTheme.primary.withValues(alpha: 0.6)
                      : AppTheme.surfaceLight),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Flexible(
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (m.leagueBadge.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Image.network(m.leagueBadge,
                              width: 16,
                              height: 16,
                              errorBuilder: (_, __, ___) => const SizedBox()),
                        ),
                      Flexible(
                        child: Text(m.league,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ])),
              ),
              const SizedBox(width: 6),
              if (isReal)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                          m.streams.length > 1
                              ? 'EN DIRECT • ${m.streams.length}'
                              : 'EN DIRECT',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold))
                    ])),
              // Sur web la sonde est désactivée (pas de CORS) : badge statique
              // au lieu du spinner infini.
              if (isPending && !kIsWeb)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.orange[800],
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(children: [
                      SizedBox(
                          width: 6,
                          height: 6,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.white)),
                      SizedBox(width: 6),
                      Text('Vérif…',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold))
                    ])),
              if (isPending && kIsWeb)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        '${m.streams.length} source${m.streams.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
              if (!isReal && isLive)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('DIRECT',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold))
                    ])),
              const SizedBox(width: 6),
              Flexible(
                child: Text('${m.dateStr} ${m.timeStr}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _team(m.home, m.homeBadge, true)),
              Column(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(score,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13))),
                const SizedBox(height: 4),
                Text(
                    isReal
                        ? 'Match réel'
                        : isPending && !kIsWeb
                            ? 'Vérification…'
                            : isLive
                                ? 'En cours'
                                : 'À venir',
                    style: TextStyle(
                        color: isReal
                            ? Colors.greenAccent
                            : isPending && !kIsWeb
                                ? Colors.orangeAccent
                                : isLive
                                    ? AppTheme.primary
                                    : Colors.white24,
                        fontSize: 10)),
              ]),
              Expanded(child: _team(m.away, m.awayBadge, false)),
            ]),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => LivePlayerScreen(match: m))),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(isReal || isPending
                        ? 'Regarder le match'
                        : 'Flux générique'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isReal || isPending
                            ? Colors.green[600]
                            : AppTheme.primary,
                        foregroundColor:
                            isReal || isPending ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10)))),
          ],
        ),
      ),
    );
  }

  Widget _team(String name, String badge, bool isHome) {
    final initials = _initials(name);
    final avatarColor = _avatarColor(name);
    Widget avatar;
    if (badge.isEmpty) {
      avatar = Container(
        decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
        child: Center(
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      );
    } else {
      avatar = Container(
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: ClipOval(
          child: Image.network(badge,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                        color: avatarColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  )),
        ),
      );
    }
    return Column(children: [
      Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12)),
          child: avatar),
      const SizedBox(height: 6),
      Text(name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  /// "Real Madrid" -> "RM", "PSG" -> "PS", "?" -> "?".
  String _initials(String name) {
    final words = name
        .replaceAll(RegExp(r'[^A-Za-zÀ-ÿ0-9 ]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  /// Couleur stable par équipe (même équipe = même couleur).
  Color _avatarColor(String name) {
    const palette = [
      Color(0xFF1B7A3D),
      Color(0xFF1565C0),
      Color(0xFFC62828),
      Color(0xFFEF6C00),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFF455A64),
      Color(0xFFAD1457),
    ];
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}
