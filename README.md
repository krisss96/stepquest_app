# StepQuest

StepQuest is a mobile exergame designed to intercept the doomscrolling habit by offering a high-stimulation, movement-based alternative.
The goal of the game is to walk steps, so as to complete challenges and win new terrotory on a map. The game encourages players to get outside and explore their surroundings while engaging in fun, competitive gameplay.

## Core Game Loop

- Move in the real world to update player position;
- Capture neutral POIs by entering their radius;
- Enter rival territory to trigger a battle challenge;
- Win battles to convert rival territory to player-owned territory;
- Keep capturing until the map is blue.

## How To Play

1. Launch the app and allow location permission
2. Use the map to find nearby neutral POIs and rival territories
3. Walk into a POI zone to capture it
4. If you enter rival territory, choose `START BATTLE!` in the battle dialog
5. In battle mode, race to the finish distance before the rival
6. On victory, the territory is claimed and shown as player-owned

## Gameplay Rules (Current Implementation)

- POI capture radius: `50m`
- Rival battle trigger distance: `100m`
- Battle dialog cooldown after dismiss: `30s`
- Battle win condition: player progress reaches `500m` before rival
- Rival progress increases over time during an active battle
- Captured territories are persisted with `SharedPreferences`

## Project Structure

```
Copy_Project/
├── lib/
│   ├── main.dart              # App entry, splash, map page, location tracking, POI capture, 
│   │                          # battle flow, dialogs, persistence, audio triggers
│   ├── battlepage.dart        # Battle UI, VS intro overlay, progress bars, charts, animations
│   ├── map.dart               # Map styling, POI coordinates, rival spawn data
│   └── rivals.dart            # Rival model definition
│
├── assets/
│   ├── 9.png                  # Game logo 
│   ├── runner.png             # Runner icon 
│   ├── finish.png             # Finish line graphic 
│   └── audio/
│       ├── mixkit-game-level-completed-2059.wav               # Victory sound
│       ├── mixkit-quick-positive-video-game-notification-interface-265.wav  # Battle start sound
│       └── zapsplat_musical_strings_orchestra_riff_short_descending_fail_107286.mp3  # Defeat sound
│
├── pubspec.yaml               # Dependencies & asset declarations
├── pubspec.lock               # Locked dependency versions
└── README.md                  
```

### File Descriptions

| File | Purpose |
|------|---------|
| `main.dart` | Core game logic, location updates, territory capture, battle initialization, dialogs |
| `battlepage.dart` | Battle UI with animated banner, progress bars, VS intro overlay, stat cards |
| `map.dart` | Google Map styling JSON, POI locations, rival spawn coordinates |
| `rivals.dart` | `Rival` class model (position, color) |

## Audio Assets & Licensing

### Sound Files Location

All audio files are stored in:
```
assets/audio/
```

### License & Attribution Details

| Audio File | Source | License Link | Usage |
|-----------|--------|--------------|-------|
| `mixkit-game-level-completed-2059.wav` | Mixkit | https://mixkit.co/license/ | Victory when capturing POI or winning battle |
| `mixkit-quick-positive-video-game-notification-interface-265.wav` | Mixkit | https://mixkit.co/license/ | Sound effect when battle starts |
| `zapsplat_musical_strings_orchestra_riff_short_descending_fail_107286.mp3` | ZapSplat | https://www.zapsplat.com/license-type/ | Defeat sound when losing a battle |

## Developer Setup

```bash
flutter pub get
flutter run
```

## Tech Stack

- Flutter
- `google_maps_flutter`
- `geolocator`
- `shared_preferences`
- `audioplayers`
- `google_fonts`