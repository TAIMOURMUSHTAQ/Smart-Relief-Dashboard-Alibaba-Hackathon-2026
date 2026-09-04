import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/relief_request.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/urgency_badge.dart';

class RequestDetailScreen extends StatelessWidget {
  final ReliefRequest request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(request.areaName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UrgencyBadge(urgency: request.urgency),
                const SizedBox(width: 12),
                StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 20),
            _DetailItem(
              icon: Icons.people_outline,
              label: 'People Count',
              value: request.headcount.toString(),
            ),
            _DetailItem(
              icon: Icons.location_on_outlined,
              label: 'Coordinates',
              value:
                  '${request.lat.toStringAsFixed(5)}, ${request.lng.toStringAsFixed(5)}',
            ),
            if (request.createdAt != null)
              _DetailItem(
                icon: Icons.access_time,
                label: 'Submitted',
                value: _formatDate(request.createdAt!),
              ),
            if (request.deliveredAt != null)
              _DetailItem(
                icon: Icons.done_all,
                label: 'Delivered',
                value: _formatDate(request.deliveredAt!),
              ),
            const SizedBox(height: 16),
            Text(
              'Items Needed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...request.itemsNeeded.map(
              (item) => ListTile(
                dense: true,
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(item.itemName),
                trailing: Text(
                  '${item.qty}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (request.allocatedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Allocated Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...request.allocatedItems.map(
                (item) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(item.itemName),
                  subtitle: Text('Warehouse: ${item.warehouseId}'),
                  trailing: Text(
                    '${item.qty}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            if (request.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(request.notes),
            ],
            if (request.photoUrl != null) ...[
              const SizedBox(height: 16),
              Text(
                'Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  request.photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Text('Could not load image'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(request.lat, request.lng),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.relief_dashboard',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(request.lat, request.lng),
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_pin,
                            color: AppTheme.urgencyColor(request.urgency),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
