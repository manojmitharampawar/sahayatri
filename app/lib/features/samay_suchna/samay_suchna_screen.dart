import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahayatri/core/api/api_client.dart';
import 'package:sahayatri/core/cache/local_db.dart';
import 'package:sahayatri/models/train_status.dart';

class SamaySuchnaScreen extends StatefulWidget {
  const SamaySuchnaScreen({super.key});

  @override
  State<SamaySuchnaScreen> createState() => _SamaySuchnaScreenState();
}

class _SamaySuchnaScreenState extends State<SamaySuchnaScreen> {
  final _trainNumberController = TextEditingController();
  TrainStatus? _status;
  bool _loading = false;
  String? _error;

  Future<void> _fetchStatus() async {
    final trainNumber = _trainNumberController.text.trim();
    if (trainNumber.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final response = await api.getTrainStatus(trainNumber);
      if (response.statusCode == 200) {
        _status = TrainStatus.fromJson(response.data as Map<String, dynamic>);
        await LocalDB.cacheTrainStatus(_status!.toJson());
      }
    } catch (_) {
      final cached = await LocalDB.getCachedTrainStatus(trainNumber);
      if (cached != null) {
        _status = TrainStatus.fromJson(cached);
      } else {
        _error = 'Train status not available';
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Samay Suchna')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _trainNumberController,
              decoration: InputDecoration(
                labelText: 'Train Number',
                hintText: 'Enter 5-digit train number',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _fetchStatus,
                ),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _fetchStatus(),
            ),
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_status != null) _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Train ${_status!.trainNumber}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _status!.isDelayed ? Icons.warning : Icons.check_circle,
                  color: _status!.isDelayed ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _status!.delayText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _status!.isDelayed ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_status!.lastFetchedAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _trainNumberController.dispose();
    super.dispose();
  }
}
