import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tigoals_match.dart';
import '../theme.dart';

class TigoalsPlayerScreen extends StatefulWidget {
  final TigoalsMatch match;
  const TigoalsPlayerScreen({super.key, required this.match});
  @override
  State<TigoalsPlayerScreen> createState() => _TigoalsPlayerScreenState();
}

class _TigoalsPlayerScreenState extends State<TigoalsPlayerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight, DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${m.homeName} vs ${m.awayName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(m.leagueEn, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _team(m.homeLogoUrl, m.homeName),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('VS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              _team(m.awayLogoUrl, m.awayName),
            ]),
            const SizedBox(height: 24),
            Text(m.leagueEn, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('${m.matchDate.day}/${m.matchDate.month} ${m.matchDate.hour}:${m.matchDate.minute.toString().padLeft(2,'0')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 24),
            const Icon(Icons.live_tv, color: AppTheme.primary, size: 48),
            const SizedBox(height: 12),
            const Text('Le flux sera disponible à l\'heure du coup d\'envoi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _team(String logo, String name) {
    return Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.network(logo.replaceFirst('http://','https://'), fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.shield, color: Colors.white24)),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(width: 100, child: Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
    ]);
  }
}
