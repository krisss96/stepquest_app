import 'package:flutter/material.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart' as ll; // latlong2 - package for handling geographical coordinates, provides the LatLng class and distance calculations
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'dart:typed_data'; // dart:typed_data - provides classes for working with binary data, used here for creating custom marker icons from byte data
import 'dart:ui' as ui; // dart:ui - provides low-level graphics operations, used here for creating custom marker icons
import 'battlepage.dart';

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
//
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
                  width: 740,
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

//Rivals
class Rival {
  final ll.LatLng position; // final- variable, can only be set once, cannot change
  final Color color;
  Rival({required this.position, required this.color});
}

class MyMapPage extends StatefulWidget { // StatefulWidget - widget that can change over time
  const MyMapPage({super.key});
  @override
  State<MyMapPage> createState() => _MyMapPageState(); // creates the state for this widget, which is defined in the _MyMapPageState class
}

class _MyMapPageState extends State<MyMapPage> {
  // this class holds the state of the MyMapPage widget, including the current position and the logic to update it

  // Custom map style - JSON string that defines the visual style of the Google Map
  final String _myMapStyle = '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#8b7474"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#e6dcdc"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#2b525e"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#1d3f49"}]}
]
''';


  // VARIABLES
  DateTime? lastDismissedTime; // keeps track of the last time a battle dialog was dismissed
  gmaps.LatLng _toGmaps(ll.LatLng p) => gmaps.LatLng(p.latitude, p.longitude);
  bool isBattleActive = false;
  double playerProgress = 0;
  double rivalProgress = 0;
  static const double _territoryMinCenterSpacingMeters = 760;
  ll.LatLng? battleStartPoint;
  Rival? currentRival;  // ? - Nullable Type, currently can be null
  gmaps.BitmapDescriptor? _towerIcon;
  gmaps.BitmapDescriptor? _flagIcon;
  gmaps.BitmapDescriptor? _purpleFlagIcon;
  gmaps.BitmapDescriptor? _playerIcon;

  List<ll.LatLng> _spacedPoi() {
    final filtered = <ll.LatLng>[];
    for (final hub in poi) {
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
  Future<gmaps.BitmapDescriptor> _getMarkerBitmap(IconData iconData, Color color, {int size = 132}) async {
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
    return gmaps.BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
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

  // Rivals
  final List<Rival> rivals = [
    Rival(position: const ll.LatLng(51.451333, 5.480772), color: Colors.redAccent),
    // Fontys
    Rival(position: ll.LatLng(51.430280, 5.499215), color: Colors.redAccent),
    // park
    Rival(position: ll.LatLng(51.4460, 5.4850), color: Colors.redAccent),
    Rival(position: const ll.LatLng(51.438400, 5.492200), color: Colors.redAccent),
    Rival(position: const ll.LatLng(51.455200, 5.468900), color: Colors.redAccent),
    // City Center
    Rival(position: const ll.LatLng(51.411092, 5.457458),
        color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.477588, 5.493336),
        color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.421900, 5.470300),
        color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.463300, 5.505200),
        color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.434700, 5.452600),
        color: Colors.purpleAccent),
    // Lidl
  ];

  List<ll.LatLng> capturedPoi = []; // keeping track on captured poi
  ll.LatLng myPosition = ll.LatLng(51.4416, 5.4897); // initial position

  // POI
  final List<ll.LatLng> poi = [
    // POI; LatLng - class, represents a geographical point with latitude and longitude
    const ll.LatLng(51.4485, 5.4571),
    // Strijp-S
    const ll.LatLng(51.4411, 5.4772),
    // The Blob
    const ll.LatLng(51.4417, 5.4674),
    // Philips Stadium
    const ll.LatLng(51.416659, 5.478230),
    const ll.LatLng(51.422788, 5.499913),
    const ll.LatLng(51.435511, 5.461900),
    const ll.LatLng(51.464703, 5.473595),
    const ll.LatLng(51.426775, 5.508957),
    const ll.LatLng(51.434882, 5.513163),
    const ll.LatLng(51.439250, 5.458700),
    const ll.LatLng(51.452900, 5.496400),
    const ll.LatLng(51.418300, 5.466100),
    const ll.LatLng(51.470800, 5.486900),
    const ll.LatLng(51.444600, 5.503800),
    const ll.LatLng(51.429900, 5.452900),
    const ll.LatLng(51.460100, 5.459300),
  ];

  @override
  void initState() {
    // initialization method, called once when the widget is first created,
    // used to set up any necessary state or start any processes that should run when the widget is displayed
    super.initState(); // standard background setup
    // !! ALWAYS CALL SUPER.INITSTATE() FIRST !!
    _initLocation();
    _loadCustomIcons();
  }

  void _initLocation() async {
    // await _determinePosition(); // shows the request box - not using for now
    _determinePosition();
    _startTracking();
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

        if (dist < 100 && !isBattleActive && isCooldownOver) {
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
    LocationPermission permission = await Geolocator.requestPermission();
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
  void showBattleDialog(Rival rival) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog( // AlertDialog - a pop-up dialog box that can display information and actions to the user
            title: Text("Enemy Territory!"),
            content: Text(
                "This area belongs to the ${rival.color == Colors.redAccent
                    ? 'Red'
                    : 'Purple'} Rival. Challenge them to a territory battle?"),

            actions: [ // list of buttons
              TextButton(
                onPressed: () {
                  setState(() {
                    lastDismissedTime = DateTime.now();
                  });
                  Navigator.pop(context);
                },
                child: const Text("Dismiss"),
              ),
              ElevatedButton( // ElevatedButton - a button with a background color, used for primary actions
                onPressed: () {
                  // onPressed: () { ... } - multi-line action
                  Navigator.pop(context); // closes the dialog
                  startBattle(rival);
                },
                child: Text("START BATTLE!"),
              ),
            ],
          ),
    );
  }

  // Battle state
  void startBattle(Rival rival) {
    setState(() {
      isBattleActive = true;
      currentRival = rival;
      playerProgress = 400; // test start value
      rivalProgress = 120;  // test start value
      battleStartPoint = myPosition;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Battle started! Walk 500 meters to win!"),
          duration: Duration(seconds: 2)),
    );
  }

  // Debug helper- manually move both runners without real-world walking.
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(playerWon ? "VICTORY!" : "DEFEAT!"),
        content: Text(playerWon
            ? "You have conquered new territory!"
            : "The rival was too fast. Train harder and try again!"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                isBattleActive = false;
                if (playerWon) {
                  capturedPoi.add(rival.position);
                  rivals.remove(rival);
                }
                playerProgress = 0;
                rivalProgress = 0;
              });
            },
            child: const Text("RETURN TO MAP"),
          ),
        ],
      ),
    );
  }


  // Build method - describes how to display the widget
  @override
  Widget build(BuildContext context) {
    final spacedPoi = _spacedPoi();
    final spacedRivals = _spacedRivals();

    return Scaffold(
      // Scaffold - provides a basic structure for the app
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            playerProgress = (playerProgress + 25).clamp(0.0, 500.0);
            rivalProgress = (rivalProgress + 15).clamp(0.0, 500.0);
          });
        },
        child: const Icon(Icons.play_arrow),
      ),
      body:Stack( // Stack - allows you to overlay multiple widgets on top of each other
          children: [
            // The Map
            gmaps.GoogleMap(
              style: _myMapStyle,
              initialCameraPosition: gmaps.CameraPosition(
                target: _toGmaps(myPosition),
                zoom: 14.0,
              ),
              myLocationEnabled: true,
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

                ...spacedPoi.map((p) => gmaps.Marker(
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
                  icon: (r.color == Colors.purpleAccent ? _purpleFlagIcon : _flagIcon) ?? // ?? - null-aware operator, if the left side is not null, use it; otherwise, use the right side
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

            if (isBattleActive)
              BattlePage(
                playerProgress: playerProgress, // Sending real movement data
                rivalProgress: rivalProgress,   // Sending bot movement data
                rivalColor: currentRival?.color ?? Colors.red, // Sending the territory color
                onIncrementProgress: _incrementBattleProgress,
              ),
          ]
      ),
    );
  }
}