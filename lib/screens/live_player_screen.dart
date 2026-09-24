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

class _LivePlayerScreenState extends State<LivePlayerScreen> with WidgetsBindingObserver {
  final _playerService = PlayerService.instance;
  bool _loading = true;
  String? _error;
  bool _playing = false;
  int _streamIdx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _playerService.initialize();
    _play();
    _playerService.player.stream.playing.listen((p) {
      if (mounted) setState(() { _playing = p; if (p) { _loading = false; _error = null; } });
    });
    _playerService.player.stream.error.listen((e) {
      if (mounted && !_playing) setState(() { _error = e.toString(); _loading = false; });
    });
  }

  Future<void> _play() async {
    setState(() { _loading = true; _error = null; });
    try {
      final streams = widget.match.streams;
      if (streams.isNotEmpty) {
        final s = streams[_streamIdx.clamp(0, streams.length - 1)];
        await _playerService.playCustom(
          s.url,
          s.headers,
          label: '${widget.match.home} vs ${widget.match.away} [${s.label}]',
        );
      } else {
        await _playerService.playCustom(
          widget.match.hlsUrl,
          const {'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36'},
          label: '${widget.match.home} vs ${widget.match.away} [générique]',
        );
      }
      try { await _playerService.player.setSubtitleTrack(SubtitleTrack.no()); } catch (_) {}
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _switchStream(int i) {
    if (i == _streamIdx) return;
    setState(() => _streamIdx = i);
    _play();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerService.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
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
      onPopInvokedWithResult: (d, r) async { if (d) return; await _exit(); },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          Center(child: Video(controller: _playerService.controller)),
          if (_loading) const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          if (_error != null) Center(child: Container(margin: const EdgeInsets.all(32), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, color: Colors.redAccent, size: 40), const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: _play, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black), child: const Text('Réessayer'))]))),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 12, right: 12, bottom: 12),
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent])),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _exit),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.match.home} vs ${widget.match.away}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    widget.match.streams.isNotEmpty
                        ? '${widget.match.league} • ${widget.match.streams[_streamIdx.clamp(0, widget.match.streams.length - 1)].label}'
                        : '${widget.match.league} • flux générique',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ])),
                if (!_loading && _error == null) IconButton(icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_filled, color: AppTheme.primary, size: 36), onPressed: () => _playing ? _playerService.pause() : _playerService.resume()),
              ]),
            ),
          ),
          // Sélecteur de source quand plusieurs flux réels (ex: beIN Ñ,
          // FAWA, STRMCNTR). Chaque source = commentateur/qualité différent.
          if (widget.match.streams.length > 1 && !_loading && _error == null)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: 12, left: 12, right: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
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
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
    );
  }
}
