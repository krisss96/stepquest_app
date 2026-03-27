import 'package:flutter/material.dart'; // basic flutter widgets
import 'package:flutter_map/flutter_map.dart'; // map widget
import 'package:latlong2/latlong.dart'; // helps map understand coordinates
import 'package:geolocator/geolocator.dart'; // GPS functionality

void main() {
  runApp(MaterialApp(home: MyMapPage()));
}

//Rivals
class Rival {
  final LatLng position; // final- variable, can only be set once, cannot change
  final Color color;
  Rival({required this.position, required this.color});
}

class MyMapPage extends StatefulWidget { // StatefulWidget - widget that can change over time
  const MyMapPage({super.key});
  @override
  State<MyMapPage> createState() => _MyMapPageState(); // creates the state for this widget, which is defined in the _MyMapPageState class
}

class _MyMapPageState extends State<MyMapPage> { // this class holds the state of the MyMapPage widget, including the current position and the logic to update it
  // variables:
  bool isBattleActive = false;
  double playerProgress = 0;
  double rivalProgress = 0;
  LatLng? battleStartPoint;
  Rival? currentRival;
  // ? - Nullable Type, currently can be null

  // Rivals
  final List<Rival> rivals = [
    Rival(position: const LatLng(51.451333, 5.480772), color: Colors.redAccent),  // Fontys
    Rival(position: LatLng(51.430280, 5.499215), color: Colors.redAccent), // park
    Rival(position: LatLng(51.4460, 5.4850), color: Colors.redAccent), // City Center
    Rival(position: const LatLng(51.448016, 5.485868), color: Colors.purpleAccent), // TUE
  ];

  List<LatLng> capturedPoi = []; // keeping track on captured poi
  LatLng myPosition = LatLng(51.4416, 5.4897); // initial position

  // POI
  final List<LatLng> poi = [ // POI; LatLng - class, represents a geographical point with latitude and longitude
    const LatLng(51.4485, 5.4571), // Strijp-S
    const LatLng(51.4411, 5.4772), // The Blob
    const LatLng(51.4417, 5.4674), // Philips Stadium
  ];
  @override
  void initState() { // initialization method, called once when the widget is first created,
    // used to set up any necessary state or start any processes that should run when the widget is displayed
    super.initState(); // standard background setup
    // !! ALWAYS CALL SUPER.INITSTATE() FIRST !!
    _initLocation();
  }

  void _initLocation() async {
    // await _determinePosition(); // shows the request box - not using for now
    _determinePosition();
    _startTracking();
  }

  // Tracking user's location
  void _startTracking() { //tells the app to listen to the GPS constantly
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // temp variable for testing
        distanceFilter: 0,
        // distanceFilter: 5, // updates every 5 meters moved
      ),
    ).listen((Position position) { // Every time the phone moves the code runs automatically
      LatLng newPoint = LatLng(position.latitude, position.longitude); // converts new position to LatLng format

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
          rivalProgress += 3.0;
        });

        if (playerProgress >= 500) {
          endBattle(true, currentRival!);
        } else if (rivalProgress >= 500) {
          endBattle(false, currentRival!);
        }
      }

      // check every hub in the list
        for (var hub in poi) {
          if (checkIfInsideHub(newPoint, hub)) { // checks if the new point is within 50m of the hub
            if (!capturedPoi.contains(hub)) {
              print("You just captured a new territory!");

              setState(() {
                capturedPoi.add(hub); // save to memory
              });
            }
          }
        }

      // checks rival location for battle challenge
      for (var rival in rivals) {
        double dist = Geolocator.distanceBetween(
            newPoint.latitude, newPoint.longitude,
            rival.position.latitude, rival.position.longitude
        );

        if (dist < 100 && !isBattleActive) {
          showBattleDialog(rival);
        }
      }

      setState(() { // updates the position
        myPosition = newPoint;
      });

    });
  }

  // Check if player is within 50 meters of a POI
  bool checkIfInsideHub(LatLng playerPos, LatLng poiPos) {
    double distance = Geolocator.distanceBetween( // double - Double-Precision Floating Point - n with decimals
      // distanceBetween - calculates the distance in meters between two geographical points - the Haversine formula
      playerPos.latitude,
      playerPos.longitude,
      poiPos.latitude,
      poiPos.longitude,
    );
    return distance < 50;
  }

  Future<Position> _determinePosition() async {// Future - this function will return a position later
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled(); // checks if the location services are enabled
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
  // This function is not used in the current implementation, but it can be called to get the current position once, instead of listening to a stream of updates. It checks for permissions and returns the current position if everything is in order.
  void updateLocation() async {
    Position position = await _determinePosition();
    setState(() {
      myPosition = LatLng(position.latitude, position.longitude);
    });
  }

  // Battle logic
  void showBattleDialog(Rival rival) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog( // AlertDialog - a pop-up dialog box that can display information and actions to the user
        title: Text("Enemy Territory!"),
        content: Text("This area belongs to the ${rival.color == Colors.redAccent ? 'Red' : 'Purple'} Rival. Challenge them to a territory battle?"),

        actions: [ // list of buttons
          TextButton(onPressed: () => Navigator.pop(context),
              // onPressed: () => ... - one line function
              child: Text("Dismiss")),
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
      playerProgress = 0;
      rivalProgress = 0;
      battleStartPoint = myPosition;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Battle started! Walk 500 meters to win!"), duration: Duration(seconds: 2)),
    );
  }

  //End battle
  void endBattle(bool playerWon, Rival rival) {
    setState(() {
      isBattleActive = false;
    });

    if (playerWon) {
      setState(() {
        capturedPoi.add(rival.position);
        rivals.remove(rival);

      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Congratulations! You conquered new territory"), duration: Duration(seconds: 3)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You lost the battle"), duration: Duration(seconds: 3)),
      );
    }

    playerProgress = 0;
    rivalProgress = 0;
  }

  @override // build method describes how to display the widget
  Widget build(BuildContext context) { // this method is called every time the state changes, and it rebuilds the UI with the new state
    return Scaffold( // basic visual layout structure
      body: FlutterMap( // main map widget
        options: const MapOptions( // map options
          initialCenter: LatLng(51.4416, 5.4697), // center of Eindhoven
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: myPosition,
                child: const Icon( // styling of icon
                  Icons.location_history,
                  color: Colors.blueAccent,
                  size: 40,
                ),
              ),
            ],
          ),
          MarkerLayer(
            markers: poi.map((poiLocation) { // poi- list of elements
              // map - goes through each element, in the () - what is currently the loop holding
              return Marker(
                point: poiLocation, // where the marker should be placed
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.flag_circle, // flag icon
                  color: Colors.orangeAccent,
                  size: 35,
                ),
              );
            }).toList(), // converts the iterable returned by map into a list, required by the markers property of MarkerLayer
          ),

          CircleLayer(
            circles: capturedPoi.map((capturedPos) {
              return CircleMarker(
                point: capturedPos, // where the circle should be placed
                color: Colors.blueAccent.withValues(alpha:0.3),
                borderStrokeWidth: 2, // thickness of the border
                borderColor: Colors.blueAccent,
                useRadiusInMeter: true, // tells the map that the radius is in meters, not pixels
                radius: 350,
              );
            }).toList(),
          ),

          // Rivals
          MarkerLayer(
            markers: rivals.map((rival) {
              return Marker(
                point: rival.position,
                width: 50,
                height: 50,
                child: Icon(
                  Icons.location_history,
                  color: rival.color,
                  size: 35,
                ),
              );
            }).toList(),
          ),

          CircleLayer(
            circles: rivals.map((rival) {
              return CircleMarker(
                point: rival.position,
                color: rival.color.withValues(alpha: 0.2),
                borderStrokeWidth: 2,
                borderColor: rival.color,
                useRadiusInMeter: true,
                radius: 350,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}