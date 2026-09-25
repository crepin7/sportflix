import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../services/player_service.dart';
import '../services/ads_service.dart';
import '../theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  final PlayerService _playerService = PlayerService.instance;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = true;
  bool _isPlaying = false;
  List<StreamVariant> _variants = const [];
  StreamVariant? _chosenVariant;
  String _qualityLabel = 'Auto ≤720p';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _playerService.initialize();
    _setupListeners();
    _playChannel();
  }

  void _setupListeners() {
    _playerService.player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          if (playing) {
            _isLoading = false;
            _errorMessage = null;
          }
        });
      }
    });

    _playerService.player.stream.error.listen((error) {
      if (mounted) {
        final errStr = error.toString().toLowerCase();

        // Ignore non-critical mpv warnings (force-seekable, etc.)
        final isIgnorable = errStr.contains('force-seekable') ||
            errStr.contains(' seekable') ||
            errStr.contains('invalid') ||
            errStr.contains('option not found');

        if (isIgnorable) return;

        final isNetworkError = errStr.contains('network') ||
            errStr.contains('connection') ||
            errStr.contains('timeout') ||
            errStr.contains('end of file') ||
            errStr.contains('eof');

        if (isNetworkError) {
          // Only show error if video is NOT playing (real failure)
          if (!_isPlaying) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted &&
                  _playerService.currentChannel != null &&
                  !_isPlaying) {
                _playChannel();
              }
            });
          }
        } else {
          // Don't show error if video is already playing successfully
          if (!_isPlaying) {
            setState(() {
              _errorMessage = 'Erreur de lecture: $error';
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  Future<void> _playChannel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _playerService.play(widget.channel);
      _loadVariants();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e);
          _isLoading = false;
        });
      }
    }
  }

  /// Qualités dispo chargées en arrière-plan (ne bloque pas la lecture).
  Future<void> _loadVariants() async {
    try {
      final headers = _playerService.headersFor(widget.channel);
      final variants =
          await _playerService.fetchVariants(widget.channel.streamUrl, headers);
      if (!mounted || variants.length <= 1) return;
      setState(() {
        _variants = variants;
        _qualityLabel = _chosenVariant?.label ?? 'Auto ≤720p';
      });
    } catch (_) {}
  }

  /// Bascule manuelle de qualité (ex: forcer 480p sur petite connexion).
  Future<void> _switchQuality(StreamVariant? v) async {
    setState(() {
      _chosenVariant = v;
      _qualityLabel = v?.label ?? 'Auto ≤720p';
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _playerService.play(widget.channel, overrideUrl: v?.url);
      _isLoading = false;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e);
          _isLoading = false;
        });
      }
    }
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
                      color: AppTheme.textPrimary,
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
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
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

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Playlist HTTP 403') || s.contains('Playlist HTTP 404')) {
      final code = s.contains('403') ? '403' : '404';
      return 'Flux hors ligne pour le moment (erreur $code).\nLa source met à jour ses liens toutes les heures — réessaie plus tard ou teste une autre chaîne.';
    }
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return 'Connexion trop lente (timeout).\nBascule en 480p via le bouton qualité si la lecture reprend.';
    }
    return 'Impossible de lire le flux: $e';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _playerService.player.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerService.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _exitPlayer() async {
    _playerService.stop();
    if (await AdsService.instance.showInterstitial()) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _exitPlayer();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Video(
                  controller: _playerService.controller,
                ),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                ),
              if (_errorMessage != null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _playChannel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _exitPlayer();
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.channel.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.channel.category,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showControls && !_isLoading && _errorMessage == null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_variants.isNotEmpty)
                          TextButton.icon(
                            onPressed: _showQualitySheet,
                            icon: const Icon(Icons.hd,
                                color: Colors.white70, size: 20),
                            label: Text(_qualityLabel,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ),
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: AppTheme.primary,
                            size: 64,
                          ),
                          onPressed: () {
                            if (_isPlaying) {
                              _playerService.pause();
                            } else {
                              _playerService.resume();
                            }
                          },
                        ),
                        if (_variants.isNotEmpty) const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
