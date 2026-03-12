import 'package:flutter/material.dart'; // basic flutter widgets
import 'package:flutter_map/flutter_map.dart'; // map widget
import 'package:latlong2/latlong.dart'; // helps map understand coordinates

void main() {
  runApp(const MaterialApp(home: MyMapPage()));
}

class MyMapPage extends StatelessWidget { 
  const MyMapPage({super.key});

  @override // build method describes how to display the widget
  Widget build(BuildContext context) {
    return Scaffold( 
      body: FlutterMap( // main map widget
        options: const MapOptions( // map options
          initialCenter: LatLng(51.5, 5.5), // center of the map (latitude, longitude)
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(51.4416, 5.4697), // pins player to location
                width: 80,
                height: 80,
                child: Icon( // styling of icon
                  Icons.location_history,
                  color: Colors.blueAccent,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ), 
    ); 
  }
}