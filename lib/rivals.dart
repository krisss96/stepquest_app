import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;

//Rivals
class Rival {
  final ll.LatLng position; // final- variable, can only be set once, cannot change
  final Color color;
  Rival({required this.position, required this.color});
}