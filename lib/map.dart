import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'rivals.dart';

class MapAssets {
  // Custom map style - JSON string that defines the visual style of the Google Map
  static const String myMapStyle = '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#8b7474"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#e6dcdc"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#2b525e"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#1d3f49"}]}
]
''';

  // Rivals
  static final List<Rival> initialRivals = [
    Rival(position: const ll.LatLng(51.451333, 5.480772), color: Colors.redAccent),
    // Fontys
    Rival(position: ll.LatLng(51.430280, 5.499215), color: Colors.redAccent),
    // park
    Rival(position: ll.LatLng(51.4460, 5.4850), color: Colors.redAccent),
    Rival(position: const ll.LatLng(51.438400, 5.492200), color: Colors.redAccent),
    Rival(position: const ll.LatLng(51.455200, 5.468900), color: Colors.redAccent),
    // City Center
    Rival(position: const ll.LatLng(51.411092, 5.457458), color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.477588, 5.493336), color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.421900, 5.470300), color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.463300, 5.505200), color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.434700, 5.452600), color: Colors.purpleAccent),
    // Lidl
  ];

  // POI
  static const List<ll.LatLng> poi = [
    // POI; LatLng - class, represents a geographical point with latitude and longitude
    ll.LatLng(51.4485, 5.4571),
    // Strijp-S
    ll.LatLng(51.4411, 5.4772),
    // The Blob
    ll.LatLng(51.4417, 5.4674),
    // Philips Stadium
    ll.LatLng(51.416659, 5.478230),
    ll.LatLng(51.422788, 5.499913),
    ll.LatLng(51.435511, 5.461900),
    ll.LatLng(51.464703, 5.473595),
    ll.LatLng(51.426775, 5.508957),
    ll.LatLng(51.434882, 5.513163),
    ll.LatLng(51.489500, 5.458000),
    ll.LatLng(51.487200, 5.523800),
    ll.LatLng(51.399800, 5.522400),
    ll.LatLng(51.398900, 5.439500),
    ll.LatLng(51.471900, 5.432200),
    ll.LatLng(51.407300, 5.531100),
    ll.LatLng(51.493100, 5.501900),
  ];
}