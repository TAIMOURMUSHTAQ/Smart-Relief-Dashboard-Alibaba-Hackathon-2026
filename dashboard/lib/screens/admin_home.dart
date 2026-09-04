import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/admin_requests_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/map_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AdminHome extends StatefulWidget {
  final int initialIndex;
  const AdminHome({super.key, this.initialIndex = 0});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AdminRequestsScreen(),
    InventoryScreen(),
    MapScreen(isAdmin: true),
  ];

  Future<void> _seedData() async {
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    await firestore.seedInitialData();
    await auth.seedDemoAccounts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo data and accounts seeded')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relief Coordinator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.eco_outlined),
            tooltip: 'Seed demo data',
            onPressed: _seedData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
