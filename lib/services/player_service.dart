import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:http/http.dart' as http;
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
    await playCustom(channel.streamUrl, headers, label: channel.name);
  }

  /// Lecture d'une URL arbitraire (ex: vrai flux live M3U) avec ses headers.
  Future<void> playCustom(String url, Map<String, String> headers,
      {String label = 'live'}) async {
    final String streamUrl = await _resolveVariant(url, headers);
    final media = Media(
      streamUrl,
      httpHeaders: headers,
    );

    debugPrint('[sportflix] play: $label');
    debugPrint('[sportflix] url: $streamUrl (orig $url)');
    debugPrint('[sportflix] headers: $headers');

    try {
      await _player.open(media);
      try { await _player.setSubtitleTrack(SubtitleTrack.no()); } catch (_) {}
    } catch (e, st) {
      debugPrint('[sportflix] open() threw: $e');
      debugPrint('[sportflix] stack: $st');
      rethrow;
    }
  }

  Future<String> _resolveVariant(String url, Map<String,String> headers) async {
    try {
      final r = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 5));
      final body = r.body;
      if (!body.contains('#EXTM3U') || !body.contains('#EXT-X-STREAM-INF')) return url;
      final lines = body.split('\n');
      String? bestVariant;
      int bestBw = -1;
      String? firstVariant;
      for (int i=0;i<lines.length;i++) {
        final l = lines[i].trim();
        if (l.startsWith('#EXT-X-STREAM-INF')) {
          final bw = int.tryParse(RegExp(r'BANDWIDTH=(\d+)').firstMatch(l)?.group(1) ?? '') ?? 0;
          final res = RegExp(r'RESOLUTION=\d+x(\d+)').firstMatch(l)?.group(1);
          final h = int.tryParse(res ?? '') ?? 0;
          String? variant;
          for (int j=i+1;j<lines.length;j++) {
            final v = lines[j].trim();
            if (v.isNotEmpty && !v.startsWith('#')) { variant = v; break; }
          }
          if (variant == null) continue;
          firstVariant ??= variant;
          if (h == 720) return Uri.parse(url).resolve(variant).toString();
          if (bw > bestBw) { bestBw = bw; bestVariant = variant; }
        }
      }
      final chosen = bestVariant ?? firstVariant;
      if (chosen != null) return Uri.parse(url).resolve(chosen).toString();
    } catch (_) {}
    return url;
  }
  
  Map<String, String> _buildHeaders(Channel channel) {
    final ua = channel.userAgent ??
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36';
    final h = <String, String>{'User-Agent': ua};
    if (channel.referer != null && channel.referer!.isNotEmpty) {
      h['Referer'] = channel.referer!;
      h['Origin'] = Uri.tryParse(channel.referer!)?.origin ?? channel.referer!;
    }

    final host = _hostOf(channel.streamUrl);
    final url = channel.streamUrl;
    if (host == 'jmp2.uk') {
      h['User-Agent'] = 'VLC/3.0.21 LibVLC/3.0.21';
      h['Referer'] = 'https://pluto.tv/';
      h['Origin'] = 'https://pluto.tv';
    } else if (host.contains('amagi.tv')) {
      h['Referer'] = 'https://www.amagi.tv/';
      h['Origin'] = 'https://www.amagi.tv';
    } else if (url.contains('cloudfront.net')) {
      if (url.contains('d3b73b34o7cvkq.cloudfront.net')) {
        h['Referer'] = 'https://animationdigitalnetwork.com/';
      } else {
        h['Referer'] = 'https://www.wurl.com/';
      }
    } else if (host.contains('wurl.com') || host.contains('37b4c228.wurl.com')) {
      h['Referer'] = 'https://www.wurl.com/';
      h['Origin'] = 'https://www.wurl.com';
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
