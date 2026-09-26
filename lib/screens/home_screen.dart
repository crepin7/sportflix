import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../services/channel_service.dart';
import '../services/ads_service.dart';
import '../services/epg_service.dart';
import '../widgets/channel_card.dart';
import '../theme.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChannelService _channelService = ChannelService.instance;
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  // channelId -> (en cours, suivant)
  Map<String, (EpgProgram?, EpgProgram?)> _epg = {};

  @override
  void initState() {
    super.initState();
    _loadEpg();
  }

  /// Guide TV en arrière-plan : n'affiche rien si indisponible.
  Future<void> _loadEpg() async {
    try {
      final wanted = _channelService.channels
          .where((c) => c.epgId != null && c.epgSource != null)
          .map((c) => (c.epgSource!, c.epgId!))
          .toSet();
      await EpgService.instance.load(wanted);
      if (!mounted) return;
      final map = <String, (EpgProgram?, EpgProgram?)>{};
      for (final c in _channelService.channels) {
        if (c.epgId != null)
          map[c.id] = EpgService.instance.programsFor(c.epgId!);
      }
      setState(() => _epg = map);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Channel> get _filteredChannels {
    List<Channel> channels;

    if (_selectedCategory != null) {
      channels = _channelService.getChannelsByCategory(_selectedCategory!);
    } else {
      channels = _channelService.channels;
    }

    if (_searchQuery.isNotEmpty) {
      channels = _channelService
          .searchChannels(_searchQuery)
          .where((c) =>
              _selectedCategory == null || c.category == _selectedCategory)
          .toList();
    }

    return channels;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _channelService.categories;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/icon/app_icon_foreground.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sport',
                              style:
                                  TextStyle(color: AppTheme.textPrimary),
                            ),
                            TextSpan(
                              text: 'flix',
                              style: TextStyle(color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une chaîne...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textSecondary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip(null, 'Toutes'),
                        const SizedBox(width: 8),
                        ...categories.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCategoryChip(cat, cat),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: _filteredChannels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune chaîne trouvée',
                            style: TextStyle(
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredChannels.length,
                      itemBuilder: (context, index) {
                        final channel = _filteredChannels[index];
                        final epg = _epg[channel.id];
                        return ChannelCard(
                          channel: channel,
                          nowPlaying: epg?.$1,
                          upNext: epg?.$2,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlayerScreen(channel: channel),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            // Bannière Start.io
            ValueListenableBuilder<bool>(
              valueListenable: AdsService.instance.bannerReady,
              builder: (context, ready, _) {
                if (!ready) return const SizedBox.shrink();
                return AdsService.instance.bannerWidget;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: AppTheme.surfaceLight,
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
