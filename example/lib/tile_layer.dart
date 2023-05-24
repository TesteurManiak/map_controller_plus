import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_controller_plus/map_controller_plus.dart';

class _TileLayerPageState extends State<TileLayerPage> {
  final mapController = MapController();

  late final statefulMapController = StatefulMapController(
    mapController: mapController,
  );
  late final StreamSubscription<StatefulMapControllerStateChange> sub;

  bool ready = false;

  @override
  void initState() {
    super.initState();
    sub = statefulMapController.changeFeed.listen((change) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: const LatLng(48.853831, 2.348722),
                zoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),
                MarkerLayer(markers: statefulMapController.markers),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }
}

class TileLayerPage extends StatefulWidget {
  const TileLayerPage({Key? key}) : super(key: key);

  @override
  _TileLayerPageState createState() => _TileLayerPageState();
}
