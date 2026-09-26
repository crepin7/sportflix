import '../models/channel.dart';

class ChannelService {
  static final ChannelService instance = ChannelService._internal();
  ChannelService._internal();

  final List<Channel> _channels = [
    const Channel(
      id: 'sport_en_france',
      name: 'Sport en France',
      streamUrl:
          'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/misc/sport-en-france-dm.m3u8',
      logoUrl: 'https://s1.dmcdn.net/u/8Dz9c1exwxFnyVPBm/60x60',
      category: 'Généraliste',
      epgId: 'Sport.en.France.fr',
      epgSource: 'fr',
    ),
    const Channel(
      id: 'equidia',
      name: 'Equidia',
      streamUrl:
          'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/equidia/live2.m3u8',
      logoUrl: 'https://i.imgur.com/QPpbRcZ.png',
      category: 'Equitation',
      epgId: 'Equidia.fr',
      epgSource: 'fr',
    ),
    const Channel(
      id: 'kozoom_tv',
      name: 'Kozoom TV',
      streamUrl:
          'https://streams2.sofast.tv/v1/master/611d79b11b77e2f571934fd80ca1413453772ac7/fdd6f243-f971-4a1a-9510-97ac01d6b37f/manifest.m3u8',
      logoUrl: 'https://i.imgur.com/M1Ee79b.png',
      category: 'Billard',
    ),
    const Channel(
      id: 'trace_sport',
      name: 'Trace Sport Stars',
      streamUrl:
          'https://lightning-tracesport-samsungau.amagi.tv/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/FabFP5A.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'africa24_sport',
      name: 'Africa 24 Sport',
      streamUrl:
          'https://africa24.vedge.infomaniak.com/livecast/ik:africa24sport/manifest.m3u8',
      logoUrl:
          'https://i0.wp.com/africa24tv.com/wp-content/uploads/2023/12/LOGO-AFRICASPORT-4-HD-sans-fond.png?fit=512%2C107&ssl=1',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'fifa_plus_fr',
      name: 'FIFA+ French',
      streamUrl:
          'https://37b4c228.wurl.com/master/f36d25e7e52f1ba8d7e56eb859c636563214f541/UmFrdXRlblRWLWZyX0ZJRkFQbHVzRnJlbmNoX0hMUw/playlist.m3u8',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/FIFA%2B_(2025).svg/960px-FIFA%2B_(2025).svg.png',
      category: 'Football',
    ),
    const Channel(
      id: 'bein_sports_xtra',
      name: 'beIN SPORTS XTRA',
      streamUrl: 'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d6/BeIN_Sports_logo_%28vertical_version%29.svg/500px-BeIN_Sports_logo_%28vertical_version%29.svg.png',
      category: 'Généraliste',
    ),
    // Chaînes sport arabes FTA (commentaires arabes, diffusent les grands
    // matchs). Sources libres iptv-org, stables.
    const Channel(
      id: 'arryadia',
      name: 'Arryadia (Maroc)',
      streamUrl: 'http://149.100.11.252:8000/play/a065/index.m3u8',
      logoUrl: 'https://i.imgur.com/XjzK3gZ.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'aliraqia_sport',
      name: 'Al Iraqia Sport',
      streamUrl: 'https://imn-live.esite-lab.com/hls/iraqia-sports-1.m3u8',
      logoUrl: 'https://i.imgur.com/DrrlxTO.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'bahrain_sport_1',
      name: 'Bahrain Sports 1',
      streamUrl:
          'https://5c7b683162943.streamlock.net/live/ngrp:sportsone_all/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/fBpLsbC.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'nba_tv',
      name: 'NBA TV',
      streamUrl: 'http://23.237.104.106:8080/USA_NBA/index.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d2/NBA_TV.svg/960px-NBA_TV.svg.png',
      category: 'Basketball',
    ),
  ];

  List<Channel> get channels => List.unmodifiable(_channels);

  List<String> get categories {
    final cats = _channels.map((c) => c.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<Channel> getChannelsByCategory(String category) {
    return _channels.where((c) => c.category == category).toList();
  }

  List<Channel> searchChannels(String query) {
    final lower = query.toLowerCase();
    return _channels
        .where((c) =>
            c.name.toLowerCase().contains(lower) ||
            c.category.toLowerCase().contains(lower))
        .toList();
  }
}
