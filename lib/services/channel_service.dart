import '../models/channel.dart';

class ChannelService {
  static final ChannelService instance = ChannelService._internal();
  ChannelService._internal();

  final List<Channel> _channels = [
    const Channel(
      id: 'lequipe',
      name: 'L\'Équipe',
      streamUrl: 'http://151.80.18.177:86/Canal+_sport_HD/index.m3u8',
      logoUrl: 'https://static-cdn.tv.sfr.net/data/logos/tv_services/L_Equipe_color.png?h=100',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'lequipe_foot',
      name: 'L\'Équipe Live Foot',
      streamUrl: 'http://151.80.18.177:86/Canal+_cinema_HD/index.m3u8',
      logoUrl: 'https://static-cdn.tv.sfr.net/data/logos/tv_services/L_Equipe_color.png?h=100',
      category: 'Football',
    ),
    const Channel(
      id: 'eurosport_1',
      name: 'Eurosport 1',
      streamUrl: 'http://151.80.18.177:86/W9_HD/index.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Eurosport_Logo_%282011-2015%29.svg/960px-Eurosport_Logo_%282011-2015%29.svg.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'eurosport_2',
      name: 'Eurosport 2',
      streamUrl: 'http://151.80.18.177:86/TMC/index.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Eurosport_Logo_%282011-2015%29.svg/960px-Eurosport_Logo_%282011-2015%29.svg.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'tennis_channel',
      name: 'Tennis Channel',
      streamUrl: 'http://151.80.18.177:86/Disney_Junior_HD/index.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Tennis_Channel_logo.svg/960px-Tennis_Channel_logo.svg.png',
      category: 'Tennis',
    ),
    const Channel(
      id: 'golf_channel',
      name: 'Golf Channel',
      streamUrl: 'http://151.80.18.177:86/Nickelodeon_Junior/index.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Golf_Channel_logo_2025.svg/960px-Golf_Channel_logo_2025.svg.png',
      category: 'Golf',
    ),
    const Channel(
      id: 'sport_en_france',
      name: 'Sport en France',
      streamUrl: 'http://99.27.51.147:8080/Gulli/index.m3u8',
      logoUrl: 'https://s1.dmcdn.net/u/8Dz9c1exwxFnyVPBm/60x60',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'equidia',
      name: 'Equidia',
      streamUrl: 'http://99.27.51.147:8080/M6/index.m3u8',
      logoUrl: 'https://i.imgur.com/QPpbRcZ.png',
      category: 'Equitation',
    ),
    const Channel(
      id: 'foot_plus',
      name: 'Foot+',
      streamUrl: 'http://145.239.5.177/556a/index.m3u8',
      logoUrl: 'https://i.imgur.com/qsLLyn4.png',
      category: 'Football',
    ),
    const Channel(
      id: 'canal_sport_360',
      name: 'CANAL+ SPORT 360',
      streamUrl: 'https://futbol9865.ultratv13.workers.dev/deportivo111/14.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/64/Canal%2BSport_360.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'rmc_sport_1',
      name: 'RMC Sport 1',
      streamUrl: 'https://7nyaler.streamhostingcdn.top/stream/59/index.m3u8',
      logoUrl: 'https://i.imgur.com/NsFTG7u.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'kozoom_tv',
      name: 'Kozoom TV',
      streamUrl: 'https://streams2.sofast.tv/v1/master/611d79b11b77e2f571934fd80ca1413453772ac7/fdd6f243-f971-4a1a-9510-97ac01d6b37f/manifest.m3u8',
      logoUrl: 'https://i.imgur.com/M1Ee79b.png',
      category: 'Billard',
    ),
    const Channel(
      id: 'trace_sport',
      name: 'Trace Sport Stars',
      streamUrl: 'https://lightning-tracesport-samsungau.amagi.tv/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/FabFP5A.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'africa24_sport',
      name: 'Africa 24 Sport',
      streamUrl: 'https://africa24.vedge.infomaniak.com/livecast/ik:africa24sport/manifest.m3u8',
      logoUrl: 'https://i0.wp.com/africa24tv.com/wp-content/uploads/2023/12/LOGO-AFRICASPORT-4-HD-sans-fond.png?fit=512%2C107&ssl=1',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'fifa_plus_fr',
      name: 'FIFA+ French',
      streamUrl: 'https://37b4c228.wurl.com/master/f36d25e7e52f1ba8d7e56eb859c636563214f541/UmFrdXRlblRWLWZyX0ZJRkFQbHVzRnJlbmNoX0hMUw/playlist.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/FIFA%2B_(2025).svg/960px-FIFA%2B_(2025).svg.png',
      category: 'Football',
    ),
    const Channel(
      id: 'bein_sports_xtra',
      name: 'beIN SPORTS XTRA',
      streamUrl: 'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d6/BeIN_Sports_logo_%28vertical_version%29.svg/500px-BeIN_Sports_logo_%28vertical_version%29.svg.png',
      category: 'Généraliste',
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
    return _channels.where((c) =>
      c.name.toLowerCase().contains(lower) ||
      c.category.toLowerCase().contains(lower)
    ).toList();
  }
}
