import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_controller_plus/src/models.dart';
import 'package:map_controller_plus/src/state/lines.dart';
import 'package:map_controller_plus/src/state/map.dart';
import 'package:map_controller_plus/src/state/markers.dart';
import 'package:map_controller_plus/src/state/polygons.dart';
import 'package:map_controller_plus/src/state/stateful_markers.dart';

/// Function to notify the changefeed
typedef FeedNotifyFunction = void Function(
  String name,
  Object? value,
  Function from,
  MapControllerChangeType type,
);

/// The map controller
base class StatefulMapController {
  /// Provide a Flutter map [MapController]
  StatefulMapController({
    required this.mapController,
    this.verbose = false,
  }) {
    // init state
    _markersState = MarkersState(mapController: mapController, notify: notify);
    _linesState = LinesState(notify: notify);
    _polygonsState = PolygonsState(notify: notify);
    _mapState = MapState(mapController: mapController, notify: notify);
    _statefulMarkersState = StatefulMarkersState(
      mapController: mapController,
      notify: notify,
    );
  }

  /// The Flutter Map [MapController]
  final MapController mapController;

  /// The Flutter Map [MapOptions]
  MapOptions? mapOptions;

  /// Verbosity level
  final bool verbose;

  late MapState _mapState;
  late MarkersState _markersState;
  late LinesState _linesState;
  late PolygonsState _polygonsState;
  late StatefulMarkersState _statefulMarkersState;

  final _subject =
      StreamController<StatefulMapControllerStateChange>.broadcast();

  /// A stream with changes occuring on the map
  Stream<StatefulMapControllerStateChange> get changeFeed => _subject.stream;

  /// The map zoom value
  double get zoom => mapController.zoom;

  /// Rotate the map
  set rotate(double degree) => mapController.rotate(degree);

  /// The map center value
  LatLng get center => mapController.center;

  /// The stateful markers present on the map
  Map<String, StatefulMarker> get statefulMarkers =>
      _statefulMarkersState.statefulMarkers;

  void addStatefulMarker({
    required String name,
    required StatefulMarker statefulMarker,
  }) =>
      _statefulMarkersState.addStatefulMarker(name, statefulMarker);

  void addStatefulMarkers(Map<String, StatefulMarker> statefulMarkers) =>
      _statefulMarkersState.addStatefulMarkers(statefulMarkers);

  void mutateMarker({
    required String name,
    required String property,
    required Object? value,
  }) =>
      _statefulMarkersState.mutate(name, property, value);

  /// The markers present on the map
  List<Marker> get markers {
    final localMarkers = <Marker>[
      ..._markersState.markers,
      ..._statefulMarkersState.markers
    ];
    return localMarkers;
  }

  /// Return a [Marker] corresponding to [name] from the [StatefulMarkersState].
  Marker? getMarker(String name) {
    final marker = _statefulMarkersState.statefulMarkers[name];
    return marker?.marker;
  }

  /// Return all [Marker] which have their name in [names].
  ///
  /// If one of the name doesn't correspond to any marker it is not added
  /// to the returned list.
  ///
  /// If no markers were found return an empty list.
  List<Marker> getMarkers(List<String> names) {
    final markers = <Marker>[];
    final localStatefulMarkers = _statefulMarkersState.statefulMarkers;
    for (final name in names) {
      final marker = localStatefulMarkers[name];
      if (marker != null) markers.add(marker.marker);
    }
    return markers;
  }

  /// The markers present on the map and their names
  Map<String, Marker> get namedMarkers => _markersState.namedMarkers;

  /// The lines present on the map
  List<Polyline> get lines => _linesState.lines;

  /// The named lines present on the map
  Map<String, Polyline> get namedLines => _linesState.namedLines;

  /// Return a [Polyline] corresponding to [name] from the [LinesState].
  ///
  /// If no corresponding line was found it will return [null].
  Polyline? getLine(String name) => _linesState.namedLines[name];

  /// Return all [Polyline] which have their name in [names].
  ///
  /// If one of the name doesn't correspond to any marker it is not added
  /// to the returned list.
  ///
  /// If no markers were found return an empty list.
  List<Polyline> getLines(List<String> names) {
    final lines = <Polyline>[];
    for (final name in names) {
      final line = getLine(name);
      if (line != null) lines.add(line);
    }
    return lines;
  }

  /// The polygons present on the map
  List<Polygon> get polygons => _polygonsState.polygons;

  /// The named polygons present on the map
  Map<String, Polygon> get namedPolygons => _polygonsState.namedPolygons;

  /// Zoom in one level
  void zoomIn() => _mapState.zoomIn();

  /// Zoom out one level
  void zoomOut() => _mapState.zoomOut();

  /// Zoom to level
  void zoomTo(double value) => _mapState.zoomTo(value);

  /// Center the map on a [LatLng]
  void centerOnPoint(LatLng point) => _mapState.centerOnPoint(point);

  /// The callback used to handle gestures and keep the state in sync
  void onPositionChanged(MapPosition pos, {required bool gesture}) =>
      _mapState.onPositionChanged(pos, gesture: gesture);

  /// Add a marker on the map
  void addMarker({required Marker marker, required String name}) =>
      _markersState.addMarker(marker: marker, name: name);

  /// Remove a marker from the map
  void removeMarker({required String name}) =>
      _markersState.removeMarker(name: name);

  /// Add multiple markers to the map
  void addMarkers({required Map<String, Marker> markers}) =>
      _markersState.addMarkers(markers: markers);

  /// Remove multiple makers from the map
  void removeMarkers({required List<String> names}) =>
      _markersState.removeMarkers(names: names);

  /// Fit bounds for all markers on map
  Future<void> fitMarkers() async => _markersState.fitAll();

  /// Fit bounds for one marker on map
  Future<void> fitMarker(String name) async => _markersState.fitOne(name);

  /// Fit bounds and zoom the map to center on a line
  void fitLine(String name) {
    final line = _linesState.namedLines[name]!;
    final bounds = LatLngBounds.fromPoints(line.points);
    mapController.fitBounds(bounds);
  }

  /// Add a line on the map
  void addLine({
    required String name,
    required List<LatLng> points,
    double width = 3.0,
    Color color = Colors.green,
    bool isDotted = false,
  }) {
    _linesState.addLine(
      name: name,
      line: Polyline(
        points: points,
        color: color,
        strokeWidth: width,
        isDotted: isDotted,
      ),
    );
  }

  /// Add a line on the map.
  void addPolyline({required String name, required Polyline polyline}) {
    _linesState.addLine(name: name, line: polyline);
  }

  /// Remove a line from the map
  void removeLine(String name) => _linesState.removeLine(name);

  /// Remove multiple lines from the map
  void removeLines(List<String> names) => _linesState.removeLines(names);

  /// Remove a polygon from the map
  void removePolygon(String name) => _polygonsState.removePolygon(name);

  /// Remove multiple polygons from the map
  void removePolygons(List<String> names) =>
      _polygonsState.removePolygons(names);

  /// Add a polygon on the map
  void addPolygon({
    required String name,
    required List<LatLng> points,
    Color color = Colors.lightBlue,
    double borderWidth = 0.0,
    Color borderColor = const Color(0xFFFFFF00),
  }) {
    return _polygonsState.addPolygon(
      name: name,
      points: points,
      color: color,
      borderWidth: borderWidth,
      borderColor: borderColor,
    );
  }

  /// Notify to the changefeed
  void notify(
    String name,
    Object? value,
    Function from,
    MapControllerChangeType type,
  ) {
    final change = StatefulMapControllerStateChange(
      name: name,
      value: value,
      from: from,
      type: type,
    );
    if (verbose) {
      debugPrint("Map state change: $change");
    }
    _subject.add(change);
  }
}
