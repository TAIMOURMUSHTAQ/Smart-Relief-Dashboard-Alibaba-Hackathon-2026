import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../models/warehouse.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'inventory_form_sheet.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<InventoryItem>>(
        stream: context.read<FirestoreService>().inventoryStream,
        builder: (context, inventorySnap) {
          return StreamBuilder<List<Warehouse>>(
            stream: context.read<FirestoreService>().warehousesStream,
            builder: (context, warehouseSnap) {
              if (inventorySnap.connectionState == ConnectionState.waiting ||
                  warehouseSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = inventorySnap.data ?? [];
              final warehouses = warehouseSnap.data ?? [];
              final warehouseMap = {
                for (final w in warehouses) w.id: w,
              };

              if (items.isEmpty) {
                return const Center(
                  child: Text('No inventory items yet. Tap + to add one.'),
                );
              }

              final grouped = <String, List<InventoryItem>>{};
              for (final item in items) {
                grouped.putIfAbsent(item.category, () => []).add(item);
              }
              final categories = grouped.keys.toList()..sort();

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final categoryItems = grouped[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          category,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      ...categoryItems.map(
                        (item) => _InventoryCard(
                          item: item,
                          warehouse: warehouseMap[item.warehouseId],
                          warehouses: warehouses,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {InventoryItem? item}) async {
    final warehouses = await context.read<FirestoreService>().warehousesStream.first;
    if (!context.mounted) return;
    if (warehouses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a warehouse first (seed demo data from the menu).'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return InventoryFormSheet(item: item, warehouses: warehouses);
      },
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final Warehouse? warehouse;
  final List<Warehouse> warehouses;

  const _InventoryCard({
    required this.item,
    required this.warehouse,
    required this.warehouses,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.quantity < item.lowStockThreshold;

    return Card(
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) {
              return InventoryFormSheet(item: item, warehouses: warehouses);
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      warehouse?.name ?? 'Unknown warehouse',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.critical.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Low Stock',
                    style: TextStyle(
                      color: AppTheme.critical,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
