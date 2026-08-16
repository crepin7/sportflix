import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../services/player_service.dart';
import '../theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  final PlayerService _playerService = PlayerService.instance;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = true;
  bool _isPlaying = false;

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
              if (mounted && _playerService.currentChannel != null && !_isPlaying) {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de lire le flux: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _playerService.stop();
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
                            _playerService.stop();
                            Navigator.of(context).pop();
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
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
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
