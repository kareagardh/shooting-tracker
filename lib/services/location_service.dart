import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }
}
