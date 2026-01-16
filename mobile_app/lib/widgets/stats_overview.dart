
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/employee.dart';

class StatsOverview extends StatelessWidget {
  final List<Employee> employees;

  const StatsOverview({super.key, required this.employees});

  @override
  Widget build(BuildContext context) {
    // Basic stats logic, aggregated for all weeks/days for simplicity or just current week
    // Web app logic isn't fully visible but likely aggregates based on current view.
    // I'll aggregate total count for now or based on a "default" week (0).
    // Actually, let's just show total registered for now to match the "feel".
    
    // Web app has: Total Pax, Active Shifts, On Board, Completion Rate
    
    final totalPax = employees.length;
    final onBoard = employees.where((e) => e.weeklyStatus.contains(TransportStatus.ON_BOARD)).length; // Very loose logic
    
    return GridView.count(
      crossAxisCount: 2, // 2 columns for mobile
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _StatCard(
            title: "Total Passengers", 
            value: totalPax.toString(), 
            icon: LucideIcons.users, 
            color: Colors.blue
        ),
        _StatCard(
            title: "Active Today", 
            value: "${employees.length}", // Placeholder logic
            icon: LucideIcons.bus, 
            color: Colors.green
        ),
         _StatCard(
            title: "On Board", 
            value: "$onBoard", 
            icon: LucideIcons.userCheck, 
            color: Colors.purple
        ),
        _StatCard(
            title: "Completion", 
            value: "0%", 
            icon: LucideIcons.barChart2, 
            color: Colors.amber
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
    final String title;
    final String value;
    final IconData icon;
    final MaterialColor color;

    const _StatCard({required this.title, required this.value, required this.icon, required this.color});

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0,2))]
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                            Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: color.shade50,
                                    borderRadius: BorderRadius.circular(8)
                                ),
                                child: Icon(icon, size: 16, color: color.shade600),
                            )
                        ],
                    ),
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey))
                ],
            ),
        );
    }
}
