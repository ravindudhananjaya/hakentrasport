
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';

class UserCheckIn extends StatefulWidget {
  const UserCheckIn({super.key});

  @override
  State<UserCheckIn> createState() => _UserCheckInState();
}

class _UserCheckInState extends State<UserCheckIn> {
  DayOfWeek selectedDay = DayOfWeek.Monday; // Default
  int selectedWeek = 0;
  String searchTerm = '';

  @override
  void initState() {
     super.initState();
     // Set to today if possible, else Monday
     final nowDay = DateTime.now().weekday; // 1 = Mon, 7 = Sun
     // Map 1-7 to DayOfWeek
     if(nowDay <= 7) {
         // Enum is Monday=0? No in dart it's index based.
         // DayOfWeek.Monday.index is 0. 
         // DateTime.Monday is 1.
         // Let's just default to Monday for safety or map correctly.
         // DayOfWeek.values[nowDay - 1] should work if aligned.
     }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final data = appState.employees;

    // Filter Logic
    final filtered = data.filter((e) => e.day == selectedDay).toList();
    filtered.sort((a, b) => a.time.compareTo(b.time));
    
    final searchFiltered = searchTerm.isEmpty 
        ? filtered 
        : filtered.where((e) => 
            e.name.toLowerCase().contains(searchTerm.toLowerCase()) || 
            e.serialNumber.contains(searchTerm)
        ).toList();

    // Grouping Logic
    final groups = <String, List<Employee>>{};
    for(var e in searchFiltered) {
        final hour = e.time.split(':')[0];
        final key = "$hour:00 - $hour:59";
        groups.putIfAbsent(key, () => []).add(e);
    }
    final sortedKeys = groups.keys.toList()..sort();

    return Column(
      children: [
        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Day Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: DayOfWeek.values.map((day) {
                    final isSelected = day == selectedDay;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(day.name),
                        backgroundColor: isSelected ? const Color(0xFF1E293B) : Colors.grey[50],
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[600]),
                        onPressed: () => setState(() => selectedDay = day),
                        side: BorderSide.none,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Week Selector
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Align left on mobile
                      children: List.generate(5, (index) {
                          final isSelected = index == selectedWeek;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: GestureDetector(
                                onTap: () => setState(() => selectedWeek = index),
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6)
                                    ),
                                    child: Text(
                                        "WEEK ${index + 1}",
                                        style: TextStyle(
                                            fontSize: 10, 
                                            fontWeight: FontWeight.bold, 
                                            color: isSelected ? Colors.white : Colors.grey[500]
                                        ),
                                    ),
                                ),
                            ),
                          );
                      }),
                  ),
              ),
              const SizedBox(height: 16),
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search passenger...',
                  prefixIcon: const Icon(LucideIcons.search, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                onChanged: (val) => setState(() => searchTerm = val),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // List
        if (searchFiltered.isEmpty)
             const Padding(
               padding: EdgeInsets.all(32.0),
               child: Center(child: Text("No passengers found.", style: TextStyle(color: Colors.grey))),
             )
        else
            ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: sortedKeys.length,
                separatorBuilder: (_,__) => const SizedBox(height: 16),
                itemBuilder: (ctx, index) {
                    final key = sortedKeys[index];
                    final employees = groups[key]!;
                    return _GroupCard(
                        title: key, 
                        employees: employees, 
                        weekIndex: selectedWeek,
                        onStatusChange: (id, status) => appState.updateEmployeeStatus(id, selectedWeek, status),
                    );
                }
            )
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
    final String title;
    final List<Employee> employees;
    final int weekIndex;
    final Function(String, TransportStatus) onStatusChange;

    const _GroupCard({required this.title, required this.employees, required this.weekIndex, required this.onStatusChange});

    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
                children: [
                    Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.blue.shade50,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Row(
                                    children: [
                                        const Icon(LucideIcons.clock, size: 16, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text("$title Shift", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ],
                                ),
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                    child: Text("${employees.length} Pax", style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                )
                            ],
                        ),
                    ),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: employees.length,
                        itemBuilder: (ctx, idx) {
                            final emp = employees[idx];
                            final status = emp.weeklyStatus.length > weekIndex ? emp.weeklyStatus[weekIndex] : TransportStatus.PENDING;
                            
                            return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade100))
                                ),
                                child: Column(
                                    children: [
                                        Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                                    child: Column(
                                                        children: [
                                                            Text(emp.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                            const Text("Time", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                        ],
                                                    ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Row(
                                                                children: [
                                                                    Expanded(child: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                                                    Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                                        color: Colors.grey[100],
                                                                        child: Text("#${emp.serialNumber}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                                    )
                                                                ],
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Row(
                                                                children: [
                                                                    const Icon(LucideIcons.mapPin, size: 12, color: Colors.blue),
                                                                    const SizedBox(width: 4),
                                                                    Text(emp.pickupLocation, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                                                    const SizedBox(width: 8),
                                                                    Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                                                                    const SizedBox(width: 8),
                                                                    Text(emp.company, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                                                ],
                                                            )
                                                        ],
                                                    ),
                                                )
                                            ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                            children: [
                                                Expanded(
                                                    child: _StatusBtn(
                                                        label: "Ok", 
                                                        icon: LucideIcons.check, 
                                                        isActive: status == TransportStatus.DROPPED_OFF, 
                                                        color: Colors.green,
                                                        onTap: () => onStatusChange(emp.id, TransportStatus.DROPPED_OFF)
                                                    ),
                                                ),
                                                const SizedBox(width: 8),
                                                 Expanded(
                                                    child: _StatusBtn(
                                                        label: "Absent", 
                                                        icon: LucideIcons.x, 
                                                        isActive: status == TransportStatus.ABSENT, 
                                                        color: Colors.red,
                                                        onTap: () => onStatusChange(emp.id, TransportStatus.ABSENT)
                                                    ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Self Travel Button
                                                 InkWell(
                                                     onTap: () => onStatusChange(emp.id, TransportStatus.SELF_TRAVEL),
                                                     child: Container(
                                                         padding: const EdgeInsets.all(10),
                                                         decoration: BoxDecoration(
                                                             color: status == TransportStatus.SELF_TRAVEL ? Colors.grey[800] : Colors.white,
                                                             border: Border.all(color: Colors.grey.shade300),
                                                             borderRadius: BorderRadius.circular(8)
                                                         ),
                                                         child: Text(
                                                             "Self", 
                                                             style: TextStyle(
                                                                 fontWeight: FontWeight.bold, 
                                                                 color: status == TransportStatus.SELF_TRAVEL ? Colors.white : Colors.grey[600],
                                                                 fontSize: 12
                                                             )
                                                         ),
                                                     ),
                                                 )
                                            ],
                                        )
                                    ],
                                ),
                            );
                        }
                    )
                ],
            )
        );
    }
}

class _StatusBtn extends StatelessWidget {
    final String label;
    final IconData icon;
    final bool isActive;
    final MaterialColor color;
    final VoidCallback onTap;

    const _StatusBtn({required this.label, required this.icon, required this.isActive, required this.color, required this.onTap});

    @override
    Widget build(BuildContext context) {
        return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: isActive ? color : Colors.white,
                    border: Border.all(color: isActive ? color : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0,2))] : []
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(label, style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isActive ? Colors.white : Colors.grey[600],
                            fontSize: 13
                        ))
                    ],
                ),
            ),
        );
    }
}
extension Filter<T> on Iterable<T> {
    Iterable<T> filter(bool Function(T) test) => where(test);
}
