import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahayatri/core/api/api_client.dart';
import 'package:sahayatri/core/auth/auth_service.dart';
import 'package:sahayatri/core/cache/local_db.dart';
import 'package:sahayatri/models/yatra_card.dart';
import 'package:intl/intl.dart';

class YatraKhojScreen extends StatefulWidget {
  const YatraKhojScreen({super.key});

  @override
  State<YatraKhojScreen> createState() => _YatraKhojScreenState();
}

class _YatraKhojScreenState extends State<YatraKhojScreen> {
  List<YatraCard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final response = await api.getYatraCards();
      if (response.statusCode == 200) {
        final data = response.data as List;
        _cards = data
            .map((e) => YatraCard.fromJson(e as Map<String, dynamic>))
            .toList();
        await LocalDB.cacheYatraCards(
            _cards.map((c) => c.toJson()).toList());
      }
    } catch (_) {
      // Fallback to cached data
      final cached = await LocalDB.getCachedYatraCards();
      _cards = cached.map((e) => YatraCard.fromJson(e)).toList();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yatra Khoj'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => auth.logout(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState()
              : _buildCardList(),
      floatingActionButton: auth.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Journey'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.train, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No journeys found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a journey or scan SMS for IRCTC bookings',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    return RefreshIndicator(
      onRefresh: _loadCards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return _YatraCardWidget(card: card);
        },
      ),
    );
  }

  void _showAddDialog() {
    final pnrController = TextEditingController();
    final trainController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Journey'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pnrController,
              decoration: const InputDecoration(labelText: 'PNR Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trainController,
              decoration: const InputDecoration(labelText: 'Train Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createCard(pnrController.text, trainController.text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCard(String pnr, String trainNumber) async {
    try {
      final api = context.read<ApiClient>();
      await api.createYatraCard({
        'pnr': pnr,
        'train_number': trainNumber,
        'boarding_station_id': 1,
        'destination_station_id': 2,
        'journey_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add journey: $e')),
        );
      }
    }
  }
}

class _YatraCardWidget extends StatelessWidget {
  final YatraCard card;

  const _YatraCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Train ${card.trainNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _StatusChip(status: card.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('PNR: ${card.pnr}'),
            if (card.berthInfo.isNotEmpty) Text('Berth: ${card.berthInfo}'),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(card.journeyDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'upcoming':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
