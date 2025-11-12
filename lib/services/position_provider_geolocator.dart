import 'package:geolocator/geolocator.dart';
import 'position_provider.dart';

class GeolocatorPositionProvider implements PositionProvider {
  Future<bool> _ensurePermitted() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return !(p == LocationPermission.denied ||
        p == LocationPermission.deniedForever);
  }

  @override
  Future<LatLng?> getCurrent() async {
    if (!await _ensurePermitted()) return null;
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return (lat: pos.latitude, lon: pos.longitude);
  }
}
