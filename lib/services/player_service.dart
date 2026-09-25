import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

/// Une qualité disponible dans une playlist HLS master.
class StreamVariant {
  final String url;
  final String label; // "1080p", "720p", "480p", "Audio"...
  final int height; // 0 si inconnu
  final int bandwidth; // bits/s, 0 si inconnu

  const StreamVariant({
    required this.url,
    required this.label,
    this.height = 0,
    this.bandwidth = 0,
  });
}

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

  Future<void> play(Channel channel, {String? overrideUrl}) async {
    _currentChannel = channel;

    final headers = _buildHeaders(channel);
    await playCustom(channel.streamUrl, headers,
        label: channel.name, overrideUrl: overrideUrl);
  }

  /// Lecture d'une URL arbitraire (ex: vrai flux live M3U) avec ses headers.
  /// Si [overrideUrl] est fourni (qualité choisie), on le lit directement.
  Future<void> playCustom(String url, Map<String, String> headers,
      {String label = 'live', String? overrideUrl}) async {
    final String streamUrl =
        overrideUrl ?? await _resolveVariant(url, headers);
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

  /// Qualité par défaut : la meilleure ≤ 720p (les 1080p50 ~8 Mbps
  /// figent sur les petits appareils / connexions faibles).
  Future<String> _resolveVariant(String url, Map<String,String> headers) async {
    final variants = await fetchVariants(url, headers);
    if (variants.length <= 1) return url;
    final hd = variants.where((v) => v.height > 0 && v.height <= 720).toList();
    if (hd.isNotEmpty) {
      hd.sort((a, b) => b.bandwidth.compareTo(a.bandwidth));
      return hd.first.url;
    }
    // Pas d'info résolution : la variante la plus légère.
    final sorted = List<StreamVariant>.from(variants)
      ..sort((a, b) => a.bandwidth.compareTo(b.bandwidth));
    return sorted.first.url;
  }

  /// Liste les qualités d'une playlist master. Une seule entrée "Auto"
  /// si le flux est déjà une playlist media (pas de variantes).
  /// Lève une [HttpException] avec le statut si la playlist est injoignable.
  Future<List<StreamVariant>> fetchVariants(
      String url, Map<String, String> headers) async {
    final r = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) {
      // Exception simple (compatible web) : les écrans détectent "Playlist HTTP xxx".
      throw Exception('Playlist HTTP ${r.statusCode} (${Uri.parse(url).host})');
    }
    final body = r.body;
    if (!body.contains('#EXTM3U') || !body.contains('#EXT-X-STREAM-INF')) {
      return [StreamVariant(url: url, label: 'Auto')];
    }
    final lines = body.split('\n');
    final out = <StreamVariant>[];
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i].trim();
      if (!l.startsWith('#EXT-X-STREAM-INF')) continue;
      final bw =
          int.tryParse(RegExp(r'BANDWIDTH=(\d+)').firstMatch(l)?.group(1) ?? '') ?? 0;
      final h = int.tryParse(
              RegExp(r'RESOLUTION=\d+x(\d+)').firstMatch(l)?.group(1) ?? '') ??
          0;
      final name =
          RegExp(r'NAME="([^"]+)"').firstMatch(l)?.group(1) ?? '';
      String? variant;
      for (int j = i + 1; j < lines.length; j++) {
        final v = lines[j].trim();
        if (v.isNotEmpty && !v.startsWith('#')) {
          variant = v;
          break;
        }
      }
      if (variant == null) continue;
      final label = h > 0
          ? '${h}p'
          : name.isNotEmpty
              ? name
              : '${(bw / 1000).round()}k';
      out.add(StreamVariant(
        url: Uri.parse(url).resolve(variant).toString(),
        label: label,
        height: h,
        bandwidth: bw,
      ));
    }
    out.sort((a, b) => b.bandwidth.compareTo(a.bandwidth));
    // Déduplique les labels (ex: 3x "480p").
    final seen = <String>{};
    return out.where((v) => seen.add(v.label)).toList();
  }

  /// Petit helper : statut HTTP d'une URL (pour messages d'erreur clairs).
  /// Retourne null si injoignable/timeout.
  Future<int?> probeStatus(String url, Map<String, String> headers) async {
    try {
      final r = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 8));
      return r.statusCode;
    } catch (_) {
      return null;
    }
  }
  
  /// Headers publics (pour lister les qualités sans relancer la lecture).
  Map<String, String> headersFor(Channel channel) => _buildHeaders(channel);

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
