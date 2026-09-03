import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';

class PlayerService {
  static final PlayerService instance = PlayerService._internal();
  PlayerService._internal();

  late final Player _player;
  late final VideoController _controller;
  Channel? _currentChannel;
  bool _initialized = false;

  Player get player => _player;
  VideoController get controller => _controller;
  Channel? get currentChannel => _currentChannel;

  void initialize() {
    if (_initialized) return;
    MediaKit.ensureInitialized();

    _player = Player(
      configuration: const PlayerConfiguration(
        logLevel: MPVLogLevel.debug,
        vo: 'gpu',
        bufferSize: 128 * 1024 * 1024,
        protocolWhitelist: ['https', 'http', 'rtmp', 'rtsp', 'mms', 'udp', 'tcp', 'data'],
      ),
    );

    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        vo: 'gpu',
        hwdec: 'mediacodec',
      ),
    );

    _initialized = true;
  }

  Future<void> play(Channel channel) async {
    _currentChannel = channel;

    final headers = _buildHeaders(channel);
    final media = Media(
      channel.streamUrl,
      httpHeaders: headers,
    );

    debugPrint('[animflix] play: ${channel.name}');
    debugPrint('[animflix] url: ${channel.streamUrl}');
    debugPrint('[animflix] headers: $headers');

    try {
      await _player.open(media);
    } catch (e, st) {
      debugPrint('[animflix] open() threw: $e');
      debugPrint('[animflix] stack: $st');
      rethrow;
    }
  }

  Map<String, String> _buildHeaders(Channel channel) {
    final ua = channel.userAgent ??
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36';
    final h = <String, String>{'User-Agent': ua};

    final host = _hostOf(channel.streamUrl);
    if (host == 'jmp2.uk') {
      h['User-Agent'] = 'VLC/3.0.21 LibVLC/3.0.21';
      h['Referer'] = 'https://pluto.tv/';
      h['Origin'] = 'https://pluto.tv';
    } else if (host == 'amg01596-gongnetworks-gong-ono-vh5f2.amagi.tv') {
      h['Referer'] = 'https://www.gongnetwork.tv/';
    } else if (channel.streamUrl.contains('cloudfront.net')) {
      h['Referer'] = 'https://www.adntv.com/';
    }
    return h;
  }

  String _hostOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentChannel = null;
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  void dispose() {
    _player.dispose();
  }
}
