/// A tiny abstraction so we can test without device plugins.
/// Returns a Dart 3 record with lat/lon or null if not available.
typedef LatLng = ({double lat, double lon});

abstract class PositionProvider {
  Future<LatLng?> getCurrent();
}
