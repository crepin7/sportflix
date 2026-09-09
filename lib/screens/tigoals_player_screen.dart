import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/tigoals_match.dart';
import '../theme.dart';

class TigoalsPlayerScreen extends StatefulWidget {
  final TigoalsMatch match;
  const TigoalsPlayerScreen({super.key, required this.match});
  @override
  State<TigoalsPlayerScreen> createState() => _TigoalsPlayerScreenState();
}

class _TigoalsPlayerScreenState extends State<TigoalsPlayerScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _m3u8Detected;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight, DeviceOrientation.portraitUp]);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36')
      ..addJavaScriptChannel('TigoalsBridge', onMessageReceived: (msg) {
        final url = msg.message;
        if (url.contains('.m3u8') && mounted) {
          setState(() => _m3u8Detected = url);
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) async {
          setState(() => _loading = false);
          await _controller.runJavaScript('''
            (function(){
              const origOpen = XMLHttpRequest.prototype.open;
              XMLHttpRequest.prototype.open = function(m,u){ this._url=u; return origOpen.apply(this, arguments); };
              const origSend = XMLHttpRequest.prototype.send;
              XMLHttpRequest.prototype.send = function(){ this.addEventListener('load', function(){ if(this._url && this._url.includes('m3u8')) TigoalsBridge.postMessage(this._url); }); return origSend.apply(this, arguments); };
              const origFetch = window.fetch;
              window.fetch = function(input, init){ const url = typeof input==='string'?input:input.url; if(url.includes('m3u8')) TigoalsBridge.postMessage(url); return origFetch.apply(this, arguments).then(r=>{ const u=r.url||url; if(u.includes('m3u8')) TigoalsBridge.postMessage(u); return r; }); };
              setInterval(()=>{ performance.getEntriesByType('resource').forEach(r=>{ if(r.name.includes('m3u8')) TigoalsBridge.postMessage(r.name); }); }, 2000);
            })();
          ''');
        },
        onWebResourceError: (e) => debugPrint('webview error \${e.description}'),
      ))
      ..loadRequest(Uri.parse(widget.match.detailUrl));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (d,r){ SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]); },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          titleSpacing: 0,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\${widget.match.homeName} vs \${widget.match.awayName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('\${widget.match.leagueEn} \u2022 \${widget.match.channelIds.isNotEmpty ? widget.match.channelIds.join(",") : "flux perso"}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
          actions: [
            if (_m3u8Detected != null) IconButton(icon: const Icon(Icons.info_outline, color: AppTheme.primary), onPressed: () => _showM3u8()),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.reload()),
          ],
        ),
        body: Stack(children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          if (_m3u8Detected != null)
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Flux m3u8 captur\u00e9 \u2014 pr\u00eat pour media_kit', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600))),
                  TextButton(onPressed: _showM3u8, child: const Text('Voir', style: TextStyle(color: Colors.black))),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  void _showM3u8() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('m3u8 d\u00e9tect\u00e9', style: TextStyle(color: Colors.white)),
      content: SelectableText(_m3u8Detected ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
      actions: [
        TextButton(onPressed: (){ Clipboard.setData(ClipboardData(text: _m3u8Detected ?? '')); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copi\u00e9'))); }, child: const Text('Copier', style: TextStyle(color: AppTheme.primary))),
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Fermer', style: TextStyle(color: Colors.white70))),
      ],
    ));
  }
}
