import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/live_sports_service.dart';
import '../services/player_service.dart';
import '../services/ads_service.dart';
import '../theme.dart';

class LivePlayerScreen extends StatefulWidget {
  final LiveMatch match;
  const LivePlayerScreen({super.key, required this.match});
  @override
  State<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends State<LivePlayerScreen>
    with WidgetsBindingObserver {
  final _playerService = PlayerService.instance;
  bool _loading = true;
  String? _error;
  bool _playing = false;
  int _streamIdx = 0;
  bool _showControls = true;
  Timer? _hideTimer;
  List<StreamVariant> _variants = const [];
  StreamVariant? _chosenVariant;
  String _qualityLabel = 'Auto ≤720p';
  Map<String, String> _headers = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _playerService.initialize();
    _play();
    _playerService.player.stream.playing.listen((p) {
      if (mounted)
        setState(() {
          _playing = p;
          if (p) {
            _loading = false;
            _error = null;
            // La lecture démarre : on laisse 4s puis on efface les contrôles
            // pour dégager le score affiché par le flux lui-même.
            _restartHideTimer();
          }
        });
    });
    _playerService.player.stream.error.listen((e) {
      if (mounted && !_playing)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    });
  }

  Future<void> _play() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final streams = widget.match.streams;
      if (streams.isNotEmpty) {
        final s = streams[_streamIdx.clamp(0, streams.length - 1)];
        _headers = s.headers;
        await _playerService.playCustom(
          s.url,
          s.headers,
          label: '${widget.match.home} vs ${widget.match.away} [${s.label}]',
          overrideUrl: _chosenVariant?.url,
        );
      } else {
        _headers = const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36'
        };
        await _playerService.playCustom(
          widget.match.hlsUrl,
          _headers,
          label: '${widget.match.home} vs ${widget.match.away} [générique]',
          overrideUrl: _chosenVariant?.url,
        );
      }
      try {
        await _playerService.player.setSubtitleTrack(SubtitleTrack.no());
      } catch (_) {}
      _loadVariants();
    } catch (e) {
      if (mounted)
        setState(() {
          _error = _friendlyError(e);
          _loading = false;
        });
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Playlist HTTP 403') || s.contains('Playlist HTTP 404')) {
      final code = s.contains('403') ? '403' : '404';
      return 'Source hors ligne (erreur $code).\nEssaie une autre source ci-dessous ou reviens plus tard.';
    }
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return 'Connexion trop lente (timeout).\nBascule en 480p via le bouton qualité si la lecture reprend.';
    }
    return s;
  }

  Future<void> _loadVariants() async {
    try {
      final base = _chosenBaseUrl();
      if (base == null) return;
      final variants = await _playerService.fetchVariants(base, _headers);
      if (!mounted || variants.length <= 1) return;
      setState(() {
        _variants = variants;
        _qualityLabel = _chosenVariant?.label ?? 'Auto ≤720p';
      });
    } catch (_) {}
  }

  String? _chosenBaseUrl() {
    final streams = widget.match.streams;
    if (streams.isNotEmpty) {
      return streams[_streamIdx.clamp(0, streams.length - 1)].url;
    }
    return widget.match.hlsUrl.isNotEmpty ? widget.match.hlsUrl : null;
  }

  Future<void> _switchQuality(StreamVariant? v) async {
    setState(() {
      _chosenVariant = v;
      _qualityLabel = v?.label ?? 'Auto ≤720p';
    });
    await _play();
  }

  void _showQualitySheet() {
    if (_variants.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Qualité vidéo',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            _qualityTile(null, 'Auto ≤720p', 'Recommandé'),
            for (final v in _variants)
              _qualityTile(v, v.label, _chosenVariant == v ? 'Actif' : null),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _qualityTile(StreamVariant? v, String label, String? badge) {
    final selected =
        (_chosenVariant == null && v == null) || _chosenVariant == v;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppTheme.primary : AppTheme.textSecondary,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: badge == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge,
                  style:
                      const TextStyle(color: AppTheme.primary, fontSize: 11)),
            ),
      onTap: () {
        Navigator.pop(context);
        if (!selected) _switchQuality(v);
      },
    );
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _restartHideTimer();
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _playing && _error == null) {
        setState(() => _showControls = false);
      }
    });
  }

  void _switchStream(int i) {
    if (i == _streamIdx) return;
    setState(() {
      _streamIdx = i;
      _chosenVariant = null;
      _variants = const [];
      _qualityLabel = 'Auto ≤720p';
    });
    _play();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _playerService.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  Future<void> _exit() async {
    _playerService.stop();
    if (await AdsService.instance.showInterstitial()) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (d, r) async {
        if (d) return;
        await _exit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(fit: StackFit.expand, children: [
          Center(child: Video(controller: _playerService.controller)),
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
          if (_error != null)
            Center(
                child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 40),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _play,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.black),
                          child: const Text('Réessayer'))
                    ]))),
          if (_showControls)
            Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  bottom: 12),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent])),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _exit),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${widget.match.home} vs ${widget.match.away}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(
                        widget.match.streams.isNotEmpty
                            ? '${widget.match.league} • ${widget.match.streams[_streamIdx.clamp(0, widget.match.streams.length - 1)].label}'
                            : '${widget.match.league} • flux générique',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ])),
                if (_variants.isNotEmpty && !_loading && _error == null)
                  TextButton.icon(
                      onPressed: _showQualitySheet,
                      icon:
                          const Icon(Icons.hd, color: Colors.white70, size: 20),
                      label: Text(_qualityLabel,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11))),
                if (!_loading && _error == null)
                  IconButton(
                      icon: Icon(
                          _playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: AppTheme.primary,
                          size: 36),
                      onPressed: () => _playing
                          ? _playerService.pause()
                          : _playerService.resume()),
              ]),
            ),
          ),
          // Sélecteur de source quand plusieurs flux réels (ex: beIN Ñ,
          // FAWA, STRMCNTR). Chaque source = commentateur/qualité différent.
          if (_showControls &&
              widget.match.streams.length > 1 &&
              !_loading &&
              _error == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: 12,
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.match.streams.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (c, i) {
                      final selected = i == _streamIdx;
                      return ChoiceChip(
                        label: Text(
                          widget.match.streams[i].label,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceLight,
                        onSelected: (_) => _switchStream(i),
                      );
                    },
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
