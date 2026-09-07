import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/map_screen.dart';
import '../services/auth_service.dart';
import 'my_requests_screen.dart';
import 'new_request_screen.dart';

class VolunteerHome extends StatefulWidget {
  final int initialIndex;
  const VolunteerHome({super.key, this.initialIndex = 0});

  @override
  State<VolunteerHome> createState() => _VolunteerHomeState();
}

class _VolunteerHomeState extends State<VolunteerHome> {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _screens = const [
    NewRequestScreen(),
    MyRequestsScreen(),
    MapScreen(isAdmin: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relief Dashboard'),
        actions: [
          IconButton(
            key: const Key('volunteer_logout'),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('volunteer_bottom_nav'),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'New Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'My Requests',
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
