import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/AttendanceProvider.dart';
import '../widgets/MapWidgets.dart';

enum MapViewMode { school, user }

class MainMapScreen extends StatelessWidget {
  const MainMapScreen({
    super.key,
    required this.viewMode,
  });

  final MapViewMode viewMode;

  static const LatLng schoolCenter =
      LatLng(-6.9676939, 107.65907373);
  static const double schoolRadius = 50;

  LatLng _getCenter(AttendanceProvider provider) {
    if (viewMode == MapViewMode.user &&
        provider.userLocation != null) {
      return provider.userLocation!;
    }
    return schoolCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        if (!provider.isLocationReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Peta Lokasi'),
            backgroundColor: const Color(0xFF0FA3D1),
          ),
          body: MapWidget(
            center: _getCenter(provider),
            radius: schoolRadius,
            viewMode: viewMode,
          ),
        );
      },
    );
  }
}
