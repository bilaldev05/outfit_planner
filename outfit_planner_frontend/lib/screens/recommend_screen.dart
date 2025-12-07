import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/services/api_service.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});
  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final ApiService api = ApiService();
  final TextEditingController _eventController = TextEditingController();
  String? _colorPref;
  String? _seasonPref;
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _getRecommendation() async {
    final event = _eventController.text.trim();
    if (event.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an event')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await api.recommendOutfit(event: event, preferColor: _colorPref, season: _seasonPref);
      setState(() => _result = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildCard(Map<String, dynamic>? item) {
    if (item == null) return const SizedBox.shrink();
    final imageUrl = api.resolveImageUrl(item['image']);
    return Card(
      child: Column(
        children: [
          imageUrl.isNotEmpty
              ? Image.network(imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => Image.asset('assets/placeholder.png', height: 140, width: double.infinity, fit: BoxFit.cover))
              : Image.asset('assets/placeholder.png', height: 140, width: double.infinity, fit: BoxFit.cover),
          ListTile(title: Text(item['name'] ?? 'Unknown'), subtitle: Text('${item['category'] ?? ''} • ${item['color'] ?? ''}')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(controller: _eventController, decoration: const InputDecoration(labelText: 'Event (e.g., wedding, office party)')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(onChanged: (v) => _colorPref = v, decoration: const InputDecoration(labelText: 'Preferred color (optional)'))),
              const SizedBox(width: 8),
              SizedBox(width: 120, child: TextField(onChanged: (v) => _seasonPref = v, decoration: const InputDecoration(labelText: 'Season'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loading ? null : _getRecommendation, child: _loading ? const CircularProgressIndicator() : const Text('Suggest Outfit')),
          const SizedBox(height: 12),
          if (_result != null) ...[
            Text('Suggested outfit for "${_result!['event']}"', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildCard(_result!['outfit']?['top']),
            _buildCard(_result!['outfit']?['bottom']),
            _buildCard(_result!['outfit']?['shoes']),
            _buildCard(_result!['outfit']?['outerwear']),
            _buildCard(_result!['outfit']?['accessory']),
          ]
        ],
      ),
    );
  }
}
