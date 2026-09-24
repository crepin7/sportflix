class Channel {
  final String id;
  final String name;
  final String streamUrl;
  final String logoUrl;
  final String category;
  final String? userAgent;
  final String? referer;

  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.logoUrl,
    required this.category,
    this.userAgent,
    this.referer,
  });
}
