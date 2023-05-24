import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_controller_plus/src/controller.dart';
import 'package:map_controller_plus/src/models.dart';

/// State of the polygons on the map
base class PolygonsState {
  /// Default contructor
  PolygonsState({required this.notify});

  /// The notify function
  final FeedNotifyFunction notify;

  final _namedPolygons = <String, Polygon>{};

  /// The named polygons on the map
  Map<String, Polygon> get namedPolygons => _namedPolygons;

  /// The lines present on the map
  List<Polygon> get polygons => _namedPolygons.values.toList();

  /// Add a polygon on the map
  void addPolygon({
    required String name,
    required List<LatLng> points,
    required Color color,
    required double borderWidth,
    required Color borderColor,
  }) {
    _namedPolygons[name] = Polygon(
      points: points,
      color: color,
      borderStrokeWidth: borderWidth,
      borderColor: borderColor,
    );
    notify(
      "updatePolygons",
      _namedPolygons[name],
      addPolygon,
      MapControllerChangeType.polygons,
    );
  }

  /// Remove a polygon from the map
  void removePolygon(String name) {
    if (_namedPolygons.containsKey(name)) {
      _namedPolygons.remove(name);
      notify(
        "updatePolygons",
        name,
        removePolygon,
        MapControllerChangeType.polygons,
      );
    }
  }

  /// Remove multiple polygons from the map
  void removePolygons(List<String> names) {
    _namedPolygons.removeWhere((key, value) => names.contains(key));
    notify(
      "updatePolygons",
      names,
      removePolygons,
      MapControllerChangeType.polygons,
    );
  }
}
