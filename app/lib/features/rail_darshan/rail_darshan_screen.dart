import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sahayatri/core/api/api_client.dart';

class RailDarshanScreen extends StatefulWidget {
  const RailDarshanScreen({super.key});

  @override
  State<RailDarshanScreen> createState() => _RailDarshanScreenState();
}

class _RailDarshanScreenState extends State<RailDarshanScreen> {
  final MapController _mapController = MapController();
  List<Polyline> _trackLines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final api = context.read<ApiClient>();
      final response = await api.getTrackShapefiles();
      if (response.statusCode == 200) {
        final features = response.data['features'] as List? ?? [];
        final lines = <Polyline>[];

        for (final feature in features) {
          final geometry = feature['geometry'];
          if (geometry['type'] == 'LineString') {
            final coords = geometry['coordinates'] as List;
            final points = coords
                .map((c) => LatLng((c[1] as num).toDouble(),
                    (c[0] as num).toDouble()))
                .toList();
            lines.add(Polyline(
              points: points,
              color: Colors.teal,
              strokeWidth: 2,
            ));
          }
        }

        setState(() => _trackLines = lines);
      }
    } catch (_) {
      // Tracks not available offline yet
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rail Darshan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(20.5937, 78.9629),
                initialZoom: 5.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sahayatri.app',
                ),
                PolylineLayer(polylines: _trackLines),
              ],
            ),
    );
  }
}
