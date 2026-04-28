import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahayatri/core/api/ws_client.dart';

class LiveViewScreen extends StatefulWidget {
  final int yatraId;

  const LiveViewScreen({super.key, required this.yatraId});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  final WSClient _wsClient = WSClient();
  final MapController _mapController = MapController();
  final List<Marker> _memberMarkers = [];
  LatLng? _lastPosition;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    _wsClient.connect(widget.yatraId, token);

    _wsClient.messages.listen((data) {
      final lat = (data['lat'] as num?)?.toDouble();
      final lon = (data['lon'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        setState(() {
          _lastPosition = LatLng(lat, lon);
          _memberMarkers.clear();
          _memberMarkers.add(
            Marker(
              point: _lastPosition!,
              width: 40,
              height: 40,
              child: const Icon(Icons.person_pin_circle,
                  color: Colors.teal, size: 40),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Family View'),
        actions: [
          if (_wsClient.isConnected)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.wifi, color: Colors.green),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.wifi_off, color: Colors.red),
            ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _lastPosition ?? const LatLng(20.5937, 78.9629),
          initialZoom: _lastPosition != null ? 12.0 : 5.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.sahayatri.app',
          ),
          MarkerLayer(markers: _memberMarkers),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wsClient.dispose();
    super.dispose();
  }
}
