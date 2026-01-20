import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../screens/MainMapScreen.dart';

class MapWidget extends StatelessWidget {
  final LatLng center;
  final double radius;
  final MapViewMode viewMode;

  const MapWidget({
    super.key,
    required this.center,
    required this.radius,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GoogleMap(
        /// POSISI AWAL KAMERA
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: 17,
        ),

        /// KONTROL MAP
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,

        /// CIRCLE (HANYA SEKOLAH)
        circles: viewMode == MapViewMode.school
            ? {
                Circle(
                  circleId: const CircleId('school_radius'),
                  center: center,
                  radius: radius,
                  fillColor: Colors.green.withOpacity(0.2),
                  strokeColor: Colors.green,
                  strokeWidth: 2,
                ),
              }
            : {},

        /// MARKER (DIPISAHKAN)
        markers: viewMode == MapViewMode.school
            ? {
                /// MARKER SEKOLAH
                Marker(
                  markerId: const MarkerId('school_marker'),
                  position: center,
                  infoWindow: const InfoWindow(
                    title: 'Lokasi Sekolah',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              }
            : {
                /// MARKER USER
                Marker(
                  markerId: const MarkerId('user_marker'),
                  position: center,
                  infoWindow: const InfoWindow(
                    title: 'Lokasi Saya',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
      ),
    );
  }
}
