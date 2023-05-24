import 'package:flutter_map/flutter_map.dart';
import 'package:map_controller_plus/src/controller.dart';
import 'package:map_controller_plus/src/exceptions.dart';
import 'package:map_controller_plus/src/models.dart';

/// The state of the markers on the map
base class MarkersState {
  /// Provide a [MapController]
  MarkersState({
    required this.mapController,
    required this.notify,
  });

  /// The Flutter Map controller
  final MapController mapController;

  /// The notification function
  final FeedNotifyFunction notify;

  List<Marker> _markers = <Marker>[];
  final _namedMarkers = <String, Marker>{};

  /// The markers present on the map
  List<Marker> get markers => _markers;

  /// The markers present on the map and their names
  Map<String, Marker> get namedMarkers => _namedMarkers;

  /// Add a marker on the map
  void addMarker({required String name, required Marker marker}) {
    try {
      final marker = _namedMarkers[name];

      if (marker == null) return;

      final markerAt = _markerAt(marker, name);

      if (markerAt == null) {
        _markers.add(marker);
      } else {
        _markers[markerAt] = marker;
      }
    } catch (e) {
      throw MarkerException("Can not build marker $name for add: $e");
    }
    notify("updateMarkers", marker, addMarker, MapControllerChangeType.markers);
    try {
      _namedMarkers[name] = marker;
    } catch (e) {
      throw MarkerException("Can not add marker: $e");
    }
  }

  /// Remove a marker from the map
  void removeMarker({required String name}) {
    try {
      final marker = _namedMarkers[name];

      if (marker == null) return;

      final removeAt = _markerAt(marker, name);
      if (removeAt == null) {
        throw MarkerException("Can not find marker $name for removal");
      }

      _markers.removeAt(removeAt);
    } catch (e) {
      throw MarkerException("Can not build for remove marker: $e");
    }
    notify(
      "updateMarkers",
      name,
      removeMarker,
      MapControllerChangeType.markers,
    );
    try {
      final res = _namedMarkers.remove(name);
      if (res == null) {
        throw MarkerException("Marker $name not found in map");
      }
    } catch (e) {
      throw MarkerException("Can not remove marker: $e");
    }
  }

  int? _markerAt(Marker marker, String name) {
    final markerAt = _namedMarkers[name];

    if (markerAt == null) {
      throw MarkerException('Marker $name not found');
    }

    for (int i = 0; i < _markers.length; i++) {
      if (_markers[i].point == markerAt.point) {
        return i;
      }
    }

    return null;
  }

  /// Add multiple markers on the map
  void addMarkers({required Map<String, Marker> markers}) {
    try {
      for (final entry in markers.entries) {
        _namedMarkers[entry.key] = entry.value;
      }
    } catch (e) {
      throw MarkerException("Can not add markers: $e");
    }
    _buildMarkers();
    notify(
      "updateMarkers",
      markers,
      addMarkers,
      MapControllerChangeType.markers,
    );
  }

  /// Remove multiple markers from the map
  void removeMarkers({required List<String> names}) {
    for (final name in names) {
      _namedMarkers.remove(name);
    }
    _buildMarkers();
    notify(
      "updateMarkers",
      names,
      removeMarkers,
      MapControllerChangeType.markers,
    );
  }

  /// Fit a marker on map
  void fitOne(String name) {
    final marker = namedMarkers[name];

    if (marker == null) {
      throw MarkerException("Marker $name not found");
    }

    final bounds = LatLngBounds.fromPoints([marker.point]);
    mapController.fitBounds(bounds);
  }

  /// Fit all markers on map
  void fitAll() {
    final bounds = LatLngBounds.fromPoints(
      namedMarkers.entries.map((e) => e.value.point).toList(),
    );
    mapController.fitBounds(bounds);
  }

  void _buildMarkers() {
    _markers = _namedMarkers.values.toList();
  }
}
