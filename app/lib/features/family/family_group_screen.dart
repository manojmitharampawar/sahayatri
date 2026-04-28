import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahayatri/core/api/api_client.dart';
import 'package:sahayatri/models/family_group.dart';
import 'package:sahayatri/features/family/live_view_screen.dart';

class FamilyGroupScreen extends StatefulWidget {
  const FamilyGroupScreen({super.key});

  @override
  State<FamilyGroupScreen> createState() => _FamilyGroupScreenState();
}

class _FamilyGroupScreenState extends State<FamilyGroupScreen> {
  List<FamilyGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final response = await api.getFamilyGroups();
      if (response.statusCode == 200) {
        final data = response.data as List;
        _groups = data
            .map((e) => FamilyGroup.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Groups')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmptyState()
              : _buildGroupList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No family groups yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Create a group to share live journey updates'),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.group),
              ),
              title: Text(group.name),
              subtitle: Text('Created ${group.createdAt.toLocal()}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveViewScreen(yatraId: group.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Family Group'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Group Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createGroup(nameController.text);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup(String name) async {
    if (name.isEmpty) return;
    try {
      final api = context.read<ApiClient>();
      await api.createFamilyGroup(name);
      _loadGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    }
  }
}
