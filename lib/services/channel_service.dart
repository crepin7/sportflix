import '../models/channel.dart';

class ChannelService {
  static final ChannelService instance = ChannelService._internal();
  ChannelService._internal();

  final List<Channel> _channels = [
    const Channel(
      id: 'lequipe',
      name: 'L\'Équipe',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/la-chaine-l-equipe-en-direct-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Sport_en_France_logo.svg/512px-Sport_en_France_logo.svg.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'lequipe_foot',
      name: 'L\'Équipe Live Foot',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/l-equipe-live-foot-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Sport_en_France_logo.svg/512px-Sport_en_France_logo.svg.png',
      category: 'Football',
    ),
    const Channel(
      id: 'eurosport_1',
      name: 'Eurosport 1',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/eurosport-1-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Eurosport_2015.svg/512px-Eurosport_2015.svg.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'eurosport_2',
      name: 'Eurosport 2',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/eurosport-2-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Eurosport_2015.svg/512px-Eurosport_2015.svg.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'tennis_channel',
      name: 'Tennis Channel',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/tennis-channel-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/9/9c/Tennis_Channel_logo.svg/512px-Tennis_Channel_logo.svg.png',
      category: 'Tennis',
    ),
    const Channel(
      id: 'golf_channel',
      name: 'Golf Channel',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/journal-du-golf-tv-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/3/33/Golf_Channel_logo.svg/512px-Golf_Channel_logo.svg.png',
      category: 'Golf',
    ),
    const Channel(
      id: 'sport_en_france',
      name: 'Sport en France',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/misc/sport-en-france-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Sport_en_France_logo.svg/512px-Sport_en_France_logo.svg.png',
      category: 'Généraliste',
    ),
    const Channel(
      id: 'equidia',
      name: 'Equidia',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/equidia/live2.m3u8',
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
