import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../models/relief_request.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<ReliefRequest>>(
        stream: context.read<FirestoreService>().allRequestsStream,
        builder: (context, requestSnap) {
          return StreamBuilder<List<InventoryItem>>(
            stream: context.read<FirestoreService>().inventoryStream,
            builder: (context, inventorySnap) {
              if (requestSnap.connectionState == ConnectionState.waiting ||
                  inventorySnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (requestSnap.hasError || inventorySnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load dashboard data:\n'
                      '${requestSnap.error ?? inventorySnap.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final requests = requestSnap.data ?? [];
              final inventory = inventorySnap.data ?? [];

              final activeRequests = requests
                  .where((r) => r.status != ReliefRequest.statusDelivered)
                  .toList();
              final criticalHigh = requests
                  .where(
                    (r) =>
                        (r.urgency == ReliefRequest.urgencyCritical ||
                            r.urgency == ReliefRequest.urgencyHigh) &&
                        r.status != ReliefRequest.statusDelivered,
                  )
                  .toList();
              final now = DateTime.now();
              final deliveredToday = requests.where((r) {
                return r.status == ReliefRequest.statusDelivered &&
                    r.deliveredAt != null &&
                    _isSameDay(r.deliveredAt!, now);
              }).toList();
              final deliveredThisWeek = requests.where((r) {
                return r.status == ReliefRequest.statusDelivered &&
                    r.deliveredAt != null &&
                    _isSameWeek(r.deliveredAt!, now);
              }).toList();
              final peopleServed = requests
                  .where((r) => r.status == ReliefRequest.statusDelivered)
                  .fold(0, (sum, r) => sum + r.headcount);
              final lowStock = inventory
                  .where((i) => i.quantity < i.lowStockThreshold)
                  .toList();

              final statusCounts = <String, int>{};
              for (final status in ReliefRequest.statuses) {
                statusCounts[status] = requests
                    .where((r) => r.status == status)
                    .length;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _SummaryCard(
                          label: 'Active Requests',
                          value: activeRequests.length.toString(),
                          color: AppTheme.primaryGreen,
                          icon: Icons.assignment_outlined,
                        ),
                        _SummaryCard(
                          label: 'Critical / High',
                          value: criticalHigh.length.toString(),
                          color: AppTheme.critical,
                          icon: Icons.warning_amber_outlined,
                        ),
                        _SummaryCard(
                          label: 'Fulfilled Today',
                          value: deliveredToday.length.toString(),
                          color: AppTheme.high,
                          icon: Icons.check_circle_outline,
                        ),
                        _SummaryCard(
                          label: 'Fulfilled This Week',
                          value: deliveredThisWeek.length.toString(),
                          color: AppTheme.medium,
                          icon: Icons.calendar_today_outlined,
                        ),
                        _SummaryCard(
                          label: 'People Served',
                          value: peopleServed.toString(),
                          color: AppTheme.primaryGreen,
                          icon: Icons.people_outline,
                        ),
                        _SummaryCard(
                          label: 'Low Stock Items',
                          value: lowStock.length.toString(),
                          color: AppTheme.critical,
                          icon: Icons.inventory_2_outlined,
                          onTap: () {
                            // Navigate to inventory tab via callback would be cleaner,
                            // but for now we just show a snackbar.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Go to Inventory tab to review.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Requests by Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _maxCount(statusCounts).toDouble() + 1,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >=
                                              ReliefRequest.statuses.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        ReliefRequest.statuses[index],
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: false),
                              barGroups:
                                  ReliefRequest.statuses.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final status = entry.value;
                                    final count = statusCounts[status] ?? 0;
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: count.toDouble(),
                                          color: AppTheme.statusColor(status),
                                          width: 24,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final diff = a.difference(b).inDays.abs();
    if (diff >= 7) return false;
    return a.weekday >= b.weekday - diff && a.weekday <= b.weekday;
  }

  int _maxCount(Map<String, int> counts) {
    if (counts.isEmpty) return 0;
    return counts.values.reduce((a, b) => a > b ? a : b);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  if (onTap != null) ...[
                    const Spacer(),
                    Icon(Icons.chevron_right, color: color, size: 20),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
