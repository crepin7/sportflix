import '../models/channel.dart';

class ChannelService {
  static final ChannelService instance = ChannelService._internal();
  ChannelService._internal();

  final List<Channel> _channels = [
    const Channel(
      id: 'lequipe',
      name: 'L\'Équipe',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/la-chaine-l-equipe-en-direct-dm.m3u8',
      logoUrl: 'https://static-cdn.tv.sfr.net/data/logos/tv_services/L_Equipe_color.png?h=100',
      category: 'Généraliste',
      epgId: "L'Equipe.fr",
      epgSource: 'fr',
    ),
    const Channel(
      id: 'lequipe_foot',
      name: 'L\'Équipe Live Foot',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/l-equipe-live-foot-dm.m3u8',
      logoUrl: 'https://static-cdn.tv.sfr.net/data/logos/tv_services/L_Equipe_color.png?h=100',
      category: 'Football',
    ),
    const Channel(
      id: 'eurosport_1',
      name: 'Eurosport 1',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/eurosport-1-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Eurosport_Logo_%282011-2015%29.svg/960px-Eurosport_Logo_%282011-2015%29.svg.png',
      category: 'Généraliste',
      epgId: 'Eurosport.1.fr',
      epgSource: 'fr',
    ),
    const Channel(
      id: 'eurosport_2',
      name: 'Eurosport 2',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/eurosport-2-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Eurosport_Logo_%282011-2015%29.svg/960px-Eurosport_Logo_%282011-2015%29.svg.png',
      category: 'Généraliste',
      epgId: 'Eurosport.2.fr',
      epgSource: 'fr',
    ),
    const Channel(
      id: 'tennis_channel',
      name: 'Tennis Channel',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/tennis-channel-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Tennis_Channel_logo.svg/960px-Tennis_Channel_logo.svg.png',
      category: 'Tennis',
    ),
    const Channel(
      id: 'golf_channel',
      name: 'Golf Channel',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/lequipe/journal-du-golf-tv-dm.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Golf_Channel_logo_2025.svg/960px-Golf_Channel_logo_2025.svg.png',
      category: 'Golf',
    ),
    const Channel(
      id: 'sport_en_france',
      name: 'Sport en France',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/misc/sport-en-france-dm.m3u8',
      logoUrl: 'https://s1.dmcdn.net/u/8Dz9c1exwxFnyVPBm/60x60',
      category: 'Généraliste',
      epgId: 'Sport.en.France.fr',
      epgSource: 'fr',
    ),
    const Channel(
      id: 'equidia',
      name: 'Equidia',
      streamUrl: 'https://raw.githubusercontent.com/Paradise-91/ParaTV/main/streams/equidia/live2.m3u8',
      logoUrl: 'https://i.imgur.com/QPpbRcZ.png',
      category: 'Equitation',
      epgId: 'Equidia.fr',
      epgSource: 'fr',
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
      epgId: 'Canal+.Sport.360.fr',
      epgSource: 'fr',
    ),
    const Channel(
      id: 'rmc_sport_1',
      name: 'RMC Sport 1',
      streamUrl: 'https://7nyaler.streamhostingcdn.top/stream/59/index.m3u8',
      logoUrl: 'https://i.imgur.com/NsFTG7u.png',
      category: 'Généraliste',
      epgId: 'RMC.Sport.1.fr',
      epgSource: 'fr',
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
    // Chaînes sport arabes FTA (commentaires arabes, diffusent les grands
    // matchs). Sources libres iptv-org, stables.
    const Channel(
      id: 'alkass_three',
      name: 'Alkass Three',
      streamUrl: 'https://streamer2.qna.org.qa/148161470_live/148161470_296.sdp/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/d57BdFh.png',
      category: 'Arabe',
    ),
    const Channel(
      id: 'arryadia',
      name: 'Arryadia (Maroc)',
      streamUrl: 'http://149.100.11.252:8000/play/a065/index.m3u8',
      logoUrl: 'https://i.imgur.com/XjzK3gZ.png',
      category: 'Arabe',
    ),
    const Channel(
      id: 'aliraqia_sport',
      name: 'Al Iraqia Sport',
      streamUrl: 'https://imn-live.esite-lab.com/hls/iraqia-sports-1.m3u8',
      logoUrl: 'https://i.imgur.com/DrrlxTO.png',
      category: 'Arabe',
    ),
    const Channel(
      id: 'bahrain_sport_1',
      name: 'Bahrain Sports 1',
      streamUrl: 'https://5c7b683162943.streamlock.net/live/ngrp:sportsone_all/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/fBpLsbC.png',
      category: 'Arabe',
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
