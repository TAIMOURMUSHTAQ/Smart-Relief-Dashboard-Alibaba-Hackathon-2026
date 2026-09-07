import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/relief_request.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/urgency_badge.dart';
import 'request_detail_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));

    return Scaffold(
      body: StreamBuilder<List<ReliefRequest>>(
        stream: context.read<FirestoreService>().requestsForVolunteerStream(
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your requests:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(
              child: Text('You haven’t submitted any requests yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _RequestListTile(request: request);
            },
          );
        },
      ),
    );
  }
}

class _RequestListTile extends StatelessWidget {
  final ReliefRequest request;

  const _RequestListTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(request: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.areaName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  UrgencyBadge(urgency: request.urgency),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusBadge(status: request.status),
                  const SizedBox(width: 12),
                  Text('${request.headcount} people'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${request.itemsNeeded.length} item types requested',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
