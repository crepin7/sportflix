# Sportflix

Application mobile Flutter pour regarder les chaînes de sport en français.

Regroupe les flux IPTV sportifs libres (L'Équipe, Eurosport 1/2, Tennis Channel, Golf Channel, Sport en France, Equidia, Foot+, CANAL+ SPORT 360, RMC Sport 1, Kozoom, Trace Sport Stars, Africa 24 Sport, FIFA+ French, beIN SPORTS XTRA). Lecteur HLS via `media_kit`.

## Fonctionnalités

- Grille de chaînes sport avec logos
- Recherche et filtrage par catégorie (Football / Tennis / Golf / Généraliste / ...)
- Lecteur plein écran avec retry auto sur erreur réseau
- Thème sombre (vert sportif)

## Construction

L'APK release est généré automatiquement par GitHub Actions (`.github/workflows/build.yml`) sur chaque push de `main`.

## Sources des flux

Flux libres issus des dépôts `bugsfreeweb/LiveTVCollector` et `Paradise-91/ParaTV` (mêmes origines que Canalflix / Animflix).
