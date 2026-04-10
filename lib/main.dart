import 'package:flutter/material.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart' as ll; // latlong2 - package for handling geographical coordinates, provides the LatLng class and distance calculations
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data'; // dart:typed_data - provides classes for working with binary data, used here for creating custom marker icons from byte data
import 'dart:ui' as ui; // dart:ui - provides low-level graphics operations, used here for creating custom marker icons
import 'battlepage.dart';
import 'rivals.dart';
import 'map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
// Loading screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyMapPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF18261F),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: Image(
                  image: AssetImage('assets/9.png'),
                  width: 1480,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyMapPage extends StatefulWidget { // StatefulWidget - widget that can change over time
  const MyMapPage({super.key});
  @override
  State<MyMapPage> createState() => _MyMapPageState(); // creates the state for this widget, which is defined in the _MyMapPageState class
}

class _MyMapPageState extends State<MyMapPage> {
  // this class holds the state of the MyMapPage widget, including the current position and the logic to update it

  // VARIABLES
  DateTime? lastDismissedTime; // keeps track of the last time a battle dialog was dismissed
  gmaps.LatLng _toGmaps(ll.LatLng p) => gmaps.LatLng(p.latitude, p.longitude);
  bool isBattleActive = false;
  bool _isVsIntroVisible = false; // controls the visibility of the VS intro overlay
  bool _isBattleDialogOpen = false;
  bool _isInstructionsHovered = false;
  double playerProgress = 0;
  double rivalProgress = 0;
  static const double _territoryMinCenterSpacingMeters = 760; // minimum distance between POI and rival centers to avoid overcrowding
  ll.LatLng? battleStartPoint; // the location where the battle started, used to calculate how far the player has moved during the battle
  Rival? currentRival;  // ? - Nullable Type, currently can be null
  gmaps.BitmapDescriptor? _towerIcon;
  gmaps.BitmapDescriptor? _flagIcon;
  gmaps.BitmapDescriptor? _purpleFlagIcon;
  gmaps.BitmapDescriptor? _playerIcon;
  Timer? _vsIntroTimer;
  late SharedPreferences _prefs; // late - variable that will be initialized later, used for storing captured POI persistently
  late List<Rival> rivals = List.from(MapAssets.initialRivals);
  List<ll.LatLng> capturedPoi = []; // keeping track on captured poi
  ll.LatLng myPosition = ll.LatLng(51.4416, 5.4897); // initial position
  bool _hasLocationPermission = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _battleDialogSound = 'mixkit-quick-positive-video-game-notification-interface-265.wav';
  static const String _victorySound = 'mixkit-game-level-completed-2059.wav';
  static const String _defeatSound = 'zapsplat_musical_strings_orchestra_riff_short_descending_fail_107286.mp3';

  void _playBattleSound(String fileName) async {
    await _audioPlayer.play(AssetSource('audio/$fileName'));
  }

  List<ll.LatLng> _spacedPoi() {
    final filtered = <ll.LatLng>[];
    for (final hub in MapAssets.poi) {
      if (_isFarEnoughFromExisting(hub, filtered)) {
        filtered.add(hub);
      }
    }
    return filtered;
  }

  List<Rival> _spacedRivals() {
    final filtered = <Rival>[];
    final acceptedPositions = <ll.LatLng>[];
    for (final rival in rivals) {
      if (capturedPoi.contains(rival.position)) {
        continue;
      }
      if (_isFarEnoughFromExisting(rival.position, acceptedPositions)) {
        filtered.add(rival);
        acceptedPositions.add(rival.position);
      }
    }
    return filtered;
  }

  bool _isFarEnoughFromExisting(ll.LatLng candidate, List<ll.LatLng> accepted) {
    for (final existing in accepted) {
      final distance = Geolocator.distanceBetween(
        candidate.latitude,
        candidate.longitude,
        existing.latitude,
        existing.longitude,
      );
      if (distance < _territoryMinCenterSpacingMeters) {
        return false;
      }
    }
    return true;
  }

  // Custom marker generation
  Future<gmaps.BitmapDescriptor> _getMarkerBitmap(IconData iconData, Color color, {int size = 58}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.6,
          fontFamily: iconData.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2));

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return gmaps.BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // Load custom icons
  Future<void> _loadCustomIcons() async {
    try {
      final tower = await _getMarkerBitmap(Icons.flag, Colors.orange);
      final flag = await _getMarkerBitmap(Icons.castle, Colors.red);
      final purpleFlag = await _getMarkerBitmap(Icons.castle, Colors.purpleAccent);
      final player = await _getMarkerBitmap(Icons.person, Colors.blue);

      if (!mounted) return;
      setState(() {
        _towerIcon = tower;
        _flagIcon = flag;
        _purpleFlagIcon = purpleFlag;
        _playerIcon = player;
      });
    } catch (_) {
      // Keep Google default markers if custom marker generation fails.
    }
  }

  @override
  void initState() {
    // initialization method, called once when the widget is first created,
    // used to set up any necessary state or start any processes that should run when the widget is displayed
    super.initState(); // standard background setup
    // !! ALWAYS CALL SUPER.INITSTATE() FIRST !!
    _initLocation();
    _loadCustomIcons();
    _initPrefs();
  }

  void _initPrefs() async {
    _prefs = await SharedPreferences.getInstance(); // getInstance - retrieves the singleton instance of SharedPreferences
    _loadCapturedData();
  }

  @override
  void dispose() { // called when the widget is removed from the widget tree, used to clean up any resources or processes that were set up in initState
    _vsIntroTimer?.cancel(); // cancel the timer if it's still active to prevent memory leaks
    super.dispose(); // super-
  }

  void _initLocation() async {
    try {
      final position = await _determinePosition();
      if (!mounted) return;
      setState(() {
        _hasLocationPermission = true;
        myPosition = ll.LatLng(position.latitude, position.longitude);
      });
      _startTracking();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasLocationPermission = false;
      });
    }
  }

  // Tracking user's location
  void _startTracking() {
    //tells the app to listen to the GPS constantly
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // temp variable for testing
        distanceFilter: 0,
        // distanceFilter: 5, // updates every 5 meters moved
      ),
    ).listen((
        Position position) { // Every time the phone moves the code runs automatically
      ll.LatLng newPoint = ll.LatLng(position.latitude,
          position.longitude); // converts new position to LatLng format

      setState(() {
        myPosition = newPoint;
      });

      // Battle logic
      if (isBattleActive && battleStartPoint != null) {
        double movedDistance = Geolocator.distanceBetween(
          battleStartPoint!.latitude, battleStartPoint!.longitude,
          newPoint.latitude, newPoint.longitude,
        );

        setState(() {
          playerProgress = movedDistance;
          rivalProgress += 1.7;
        });

        if (playerProgress >= 500) {
          endBattle(true, currentRival!);
        } else if (rivalProgress >= 500) {
          endBattle(false, currentRival!);
        }
      }
      // check every hub in the list
      for (var hub in _spacedPoi()) {
        if (checkIfInsideHub(newPoint,
            hub)) { // checks if the new point is within 50m of the hub
          if (!capturedPoi.contains(hub)) {
            print("You just captured a new territory!");

            setState(() {
              capturedPoi.add(hub); // save to memory
            });
            _saveCapturedData(); // save to persistent storage
            _playBattleSound(_victorySound);
            _showPoiCaptureVictoryPopup();
          }
        }
      }

      // checks rival location for battle challenge
      for (var rival in _spacedRivals()) {
        double dist = Geolocator.distanceBetween(
            newPoint.latitude, newPoint.longitude,
            rival.position.latitude, rival.position.longitude
        );

        bool isCooldownOver = lastDismissedTime == null ||
            DateTime.now().difference(lastDismissedTime!).inSeconds > 30;

        if (dist < 100 && !isBattleActive && !_isVsIntroVisible && isCooldownOver && !_isBattleDialogOpen) {
          showBattleDialog(rival);
        }
      }

      setState(() { // updates the position
        myPosition = newPoint;
      });
    });
  }

  // Check if player is within 50 meters of a POI
  bool checkIfInsideHub(ll.LatLng playerPos, ll.LatLng poiPos) {
    double distance = Geolocator
        .distanceBetween( // double - Double-Precision Floating Point - n with decimals
      // distanceBetween - calculates the distance in meters between two geographical points - the Haversine formula
      playerPos.latitude,
      playerPos.longitude,
      poiPos.latitude,
      poiPos.longitude,
    );
    return distance < 50;
  }

  Future<Position> _determinePosition() async {
    // Future - this function will return a position later
    bool serviceEnabled = await Geolocator
        .isLocationServiceEnabled(); // checks if the location services are enabled
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    // Check for permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return Future.error('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // This function is not used in the current implementation, but it can be called to get the current position once, instead of listening to a stream of updates. It checks for permissions and returns the current position if everything is in order
  void updateLocation() async {
    Position position = await _determinePosition();
    setState(() {
      myPosition = ll.LatLng(position.latitude, position.longitude);
    });
  }

  // Battle logic
  void _showGameInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18372E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF751F), width: 1.8),
        ),
        title: Text(
          "STEPQUEST MISSION",
          style: GoogleFonts.kodeMono(
            color: const Color(0xFFFFC58A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        content: SingleChildScrollView(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "Your mission is simple: Get there.\n\n"),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.flag, size: 20, color: Color(0xFFFFC58A)),
                ),
                const TextSpan(text: " Want to claim more territory? Walk further.\n\n"),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.castle, size: 20, color: Color(0xFFFFC58A)),
                ),
                const TextSpan(text: " Want to conquer your enemies? Challenge them to a battle and be faster.\n\n"),
                const TextSpan(text: "Turn the entire map blue, one step at a time."),
              ],
            ),
            style: GoogleFonts.geologica(
              color: const Color(0xFFEAF7F2),
              height: 1.4,
              fontSize: 18,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0F231D),
              backgroundColor: const Color(0xFFFF751F),
              textStyle: GoogleFonts.geologica(
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showPoiCaptureVictoryPopup() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18372E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF751F), width: 1.8),
        ),
        title: Text(
          "TERRITORY CAPTURED!",
          style: GoogleFonts.kodeMono(
            color: const Color(0xFFFFC58A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        content: Text(
          "The map is turning blue don't stop now, the next flag is waiting!",
          style: GoogleFonts.geologica(
            color: const Color(0xFFEAF7F2),
            height: 1.4,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0F231D),
              backgroundColor: const Color(0xFFFF751F),
              textStyle: GoogleFonts.geologica(
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  // Battle logic
  void showBattleDialog(Rival rival) async {
    _isBattleDialogOpen = true;
    _playBattleSound(_battleDialogSound);
    final shouldStartBattle = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog( // AlertDialog - a pop-up dialog box that can display information and actions to the user
            backgroundColor: const Color(0xFF18372E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFFF751F), width: 1.8),
            ),
            title: Text(
              "Enemy Territory!",
              style: GoogleFonts.kodeMono(
                color: const Color(0xFFFFC58A),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            content: Text(
              "This area belongs to the ${rival.color == Colors.redAccent
                  ? 'Red'
                  : 'Purple'} Rival. Challenge them to a territory battle?",
              style: GoogleFonts.geologica(
                color: const Color(0xFFEAF7F2),
                height: 1.4,
                fontSize: 18,
              ),
            ),

            actions: [ // list of buttons
              TextButton(
                onPressed: () {
                  setState(() {
                    lastDismissedTime = DateTime.now();
                  });
                  Navigator.pop(context, false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0F231D),
                  backgroundColor: const Color(0xFFFF751F),
                  textStyle: GoogleFonts.geologica(
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Dismiss"),
              ),
              ElevatedButton( // ElevatedButton - a button with a background color, used for primary actions
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F231D),
                  backgroundColor: const Color(0xFFFF751F),
                  textStyle: GoogleFonts.geologica(
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // onPressed: () { ... } - multi-line action
                  Navigator.pop(context, true); // closes the dialog
                },
                child: const Text("START BATTLE!"),
              ),
            ],
          ),
    );

    _isBattleDialogOpen = false;

    if (shouldStartBattle == true && mounted) {
      startBattle(rival);
    }
  }

  // Battle state
  void startBattle(Rival rival) {
    _vsIntroTimer?.cancel();

    setState(() {
      isBattleActive = false;
      _isVsIntroVisible = true;
      currentRival = rival;
      playerProgress = 0;
      rivalProgress = 0;
      battleStartPoint = myPosition;
    });

    _vsIntroTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isVsIntroVisible = false;
        isBattleActive = true;
        playerProgress = 400; // test start value
        rivalProgress = 120;  // test start value
        battleStartPoint = myPosition;
      });
    });
  }

  // Debug helper: manually move both runners without real-world walking.
  void _incrementBattleProgress() {
    if (!isBattleActive || currentRival == null) return;

    setState(() {
      playerProgress = (playerProgress + 25).clamp(0.0, 500.0);
      rivalProgress = (rivalProgress + 15).clamp(0.0, 500.0);
    });

    if (playerProgress >= 500) {
      endBattle(true, currentRival!);
    } else if (rivalProgress >= 500) {
      endBattle(false, currentRival!);
    }
  }

  //End battle
  void endBattle(bool playerWon, Rival rival) {
    _playBattleSound(playerWon ? _victorySound : _defeatSound);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18372E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF751F), width: 1.8),
        ),
        title: Text(
          playerWon ? "VICTORY!" : "DEFEAT!",
          style: GoogleFonts.kodeMono(
            color: const Color(0xFFFFC58A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        content: Text(playerWon
            ? "New territory conquered!r sector claimed!Don’t let up now, there are more towers to capture!"
            : "You almost had them! Catch your breath, the rematch starts whenever you're ready!",
          style: GoogleFonts.geologica(
            color: const Color(0xFFEAF7F2),
            height: 1.4,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _vsIntroTimer?.cancel();

              setState(() {
                isBattleActive = false;
                _isVsIntroVisible = false;
                if (playerWon) {
                  capturedPoi.add(rival.position);
                  rivals.remove(rival);
                }
                playerProgress = 0;
                rivalProgress = 0;
              });
              _saveCapturedData(); // save the updated captured POI list after the battle
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0F231D),
              backgroundColor: const Color(0xFFFF751F),
              textStyle: GoogleFonts.geologica(
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("RETURN TO MAP"),
          ),
        ],
      ),
    );
  }

  // Converts LatLng and saves it as string
  void _saveCapturedData() async {
    List<String> dataToSave = capturedPoi.map((coordinate) { // map
      return "${coordinate.latitude},${coordinate.longitude}";
    }).toList();

    await _prefs.setStringList('captured_territories', dataToSave);
  }

  // Loads the captured POI from shared preferences and converts them back to LatLng
  void _loadCapturedData() {
    List<String>? savedData = _prefs.getStringList('captured_territories');
    if (savedData != null) {
      setState(() {
        capturedPoi = savedData.map((item) {
          List<String> coords = item.split(',');
          return ll.LatLng(double.parse(coords[0]), double.parse(coords[1]));
        }).toList();
      });
    }
  }


  // Build method - describes how to display the widget
  @override
  Widget build(BuildContext context) {
    final spacedPoi = _spacedPoi();
    final spacedRivals = _spacedRivals();
    final uncapturedPoi = spacedPoi.where((p) => !capturedPoi.contains(p)).toList();

    return Scaffold(
      // Scaffold - provides a basic structure for the app
      body:Stack( // Stack - allows you to overlay multiple widgets on top of each other
          children: [
            // The Map
            gmaps.GoogleMap(
              style: MapAssets.myMapStyle,
              initialCameraPosition: gmaps.CameraPosition(
                target: _toGmaps(myPosition),
                zoom: 14.0,
              ),
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: _hasLocationPermission,
              onMapCreated: (controller) {},
              // MARKER LOGIC
              markers: {
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('player'),
                  position: _toGmaps(myPosition),
                  icon: _playerIcon ??
                      gmaps.BitmapDescriptor.defaultMarkerWithHue(
                        gmaps.BitmapDescriptor.hueAzure,
                      ),
                ),

                ...capturedPoi.map((pos) => gmaps.Marker(
                  markerId: gmaps.MarkerId('captured_${pos.latitude}_${pos.longitude}'),
                  position: _toGmaps(pos),
                  icon: _playerIcon ??
                      gmaps.BitmapDescriptor.defaultMarkerWithHue(
                        gmaps.BitmapDescriptor.hueAzure,
                      ),
                )),

                ...uncapturedPoi.map((p) => gmaps.Marker(
                  markerId: gmaps.MarkerId('poi_${p.latitude}_${p.longitude}'),
                  position: _toGmaps(p),
                  icon: _towerIcon ??
                      gmaps.BitmapDescriptor.defaultMarkerWithHue(
                        gmaps.BitmapDescriptor.hueOrange,
                      ),
                )),

                ...spacedRivals.map((r) => gmaps.Marker(
                  markerId: gmaps.MarkerId('rival_${r.position.latitude}_${r.position.longitude}'),
                  position: _toGmaps(r.position),
                  icon: (r.color == Colors.purpleAccent ? _purpleFlagIcon : _flagIcon) ??
                      gmaps.BitmapDescriptor.defaultMarkerWithHue(
                        r.color == Colors.purpleAccent
                            ? gmaps.BitmapDescriptor.hueViolet
                            : gmaps.BitmapDescriptor.hueRed,
                      ),
                )),
              }.toSet(),

              //  TERRITORY LOGIC
              circles: {
                ...capturedPoi.map((pos) => gmaps.Circle(
                  // ... - cascade operator, allows you to add multiple items to a collection in a more concise way
                  circleId: gmaps.CircleId('captured_${pos.latitude}_${pos.longitude}'),
                  center: _toGmaps(pos),
                  radius: 350,
                  fillColor: Colors.blueAccent.withValues(alpha: 0.3),
                  strokeWidth: 2,
                  strokeColor: Colors.blueAccent,
                )),

                ...spacedRivals.map((r) => gmaps.Circle(
                  circleId: gmaps.CircleId(
                    'rival_territory_${r.position.latitude}_${r.position.longitude}',
                  ),
                  center: _toGmaps(r.position),
                  radius: 350,
                  fillColor: r.color.withValues(alpha: 0.2),
                  strokeWidth: 2,
                  strokeColor: r.color,
                )),
              },
            ),

            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isInstructionsHovered = true),
                    onExit: (_) => setState(() => _isInstructionsHovered = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: _isInstructionsHovered
                            ? const Color(0xFFFF8A24)
                            : const Color(0xFFB4571C),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isInstructionsHovered
                              ? const Color(0xFFFFF0DB)
                              : const Color(0xFFFFD4A3),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isInstructionsHovered
                                ? const Color(0xFFFF7A1A)
                                : const Color(0xFF8F3C10))
                                .withValues(alpha: _isInstructionsHovered ? 0.5 : 0.4),
                            blurRadius: _isInstructionsHovered ? 18 : 12,
                            spreadRadius: _isInstructionsHovered ? 2.0 : 0.8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        tooltip: 'Game Instructions',
                        iconSize: 28,
                        icon: Icon(
                          Icons.menu,
                          color: _isInstructionsHovered
                              ? const Color(0xFF1E1208)
                              : const Color(0xFFFFF4E6),
                        ),
                        onPressed: _showGameInstructions,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (isBattleActive)
              BattlePage(
                playerProgress: playerProgress, // Sending real movement data
                rivalProgress: rivalProgress,   // Sending bot movement data
                rivalColor: currentRival?.color ?? Colors.red, // Sending the territory color
                onIncrementProgress: _incrementBattleProgress,
              ),

            if (_isVsIntroVisible && currentRival != null)
              BattleVsIntroOverlay(
                playerColor: Colors.blueAccent,
                rivalColor: currentRival!.color,
              ),
          ]
      ),
    );
  }
}