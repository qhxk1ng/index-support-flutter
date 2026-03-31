import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sales_personnel_entities.dart';
import '../bloc/sales_personnel_bloc.dart';
import '../bloc/sales_personnel_event.dart';
import '../bloc/sales_personnel_state.dart';

class ActivitiesListPage extends StatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  State<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends State<ActivitiesListPage> {
  @override
  void initState() {
    super.initState();
    context.read<SalesPersonnelBloc>().add(const LoadActivitiesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activities', style: TextStyle(fontWeight: FontWeight.w700)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFF97316)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SalesPersonnelBloc>().add(const LoadActivitiesEvent()),
          ),
        ],
      ),
      body: BlocBuilder<SalesPersonnelBloc, SalesPersonnelState>(
        builder: (context, state) {
          if (state is SalesPersonnelLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)));
          }
          if (state is ActivitiesLoaded) {
            if (state.activities.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No activities yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Log your first field activity', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SalesPersonnelBloc>().add(const LoadActivitiesEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.activities.length,
                itemBuilder: (context, index) => _buildActivityCard(state.activities[index]),
              ),
            );
          }
          if (state is SalesPersonnelError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SalesPersonnelBloc>().add(const LoadActivitiesEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: ElevatedButton(
              onPressed: () => context.read<SalesPersonnelBloc>().add(const LoadActivitiesEvent()),
              child: const Text('Load Activities'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(SalesActivity activity) {
    final isActive = activity.endTime == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: isActive ? Border.all(color: const Color(0xFFEA580C), width: 2) : null,
      ),
      child: Column(
        children: [
          if (isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFEA580C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                'ONGOING',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, color: Color(0xFFEA580C), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.customerName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            activity.businessName,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(Icons.phone, activity.phoneNumber),
                    const SizedBox(width: 8),
                    if (activity.timeSpent != null)
                      _buildInfoChip(Icons.timer, '${activity.timeSpent} min'),
                  ],
                ),
                if (activity.address != null && activity.address!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.address!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ],
                if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.notes, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.notes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${activity.createdAt.day}/${activity.createdAt.month}/${activity.createdAt.year}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    Text(
                      'Lat: ${activity.latitude.toStringAsFixed(4)}, Lng: ${activity.longitude.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
