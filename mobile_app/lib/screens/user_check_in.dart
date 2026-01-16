
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
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: sortedKeys.length,
              itemBuilder: (ctx, index) {
                final key = sortedKeys[index];
                final employees = groups[key]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text("$key Shift", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text("${employees.length} Pax", style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Expanded(child: Container(height: 1, color: Colors.blue.withOpacity(0.2))),
                        ],
                      ),
                    ),

                    // Items
                    ...employees.map((emp) {
                      final companyColor = _getCompanyColor(emp.company);
                      final status = emp.weeklyStatus.length > selectedWeek ? emp.weeklyStatus[selectedWeek] : TransportStatus.PENDING;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))
                            ]
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Color Strip
                                Container(width: 6, color: companyColor),
                                
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Time Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                emp.time, 
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold, 
                                                  fontFamily: 'monospace',
                                                  color: Colors.blue.shade800,
                                                  fontSize: 13
                                                )
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
                                                      const SizedBox(width: 8),
                                                      Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          color: Colors.grey[100],
                                                          child: Text("#${emp.serialNumber}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(LucideIcons.mapPin, size: 12, color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      Expanded(child: Text(emp.pickupLocation, style: TextStyle(fontSize: 13, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(LucideIcons.building, size: 12, color: companyColor.withOpacity(0.7)),
                                                      const SizedBox(width: 4),
                                                      Text(emp.company, style: TextStyle(fontSize: 12, color: companyColor, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Actions
                                        Row(
                                          children: [
                                              Expanded(
                                                  child: _StatusBtn(
                                                      label: "Ok", 
                                                      icon: LucideIcons.check, 
                                                      isActive: status == TransportStatus.DROPPED_OFF, 
                                                      color: Colors.green,
                                                      onTap: () => appState.updateEmployeeStatus(emp.id, selectedWeek, TransportStatus.DROPPED_OFF)
                                                  ),
                                              ),
                                              const SizedBox(width: 8),
                                               Expanded(
                                                  child: _StatusBtn(
                                                      label: "Absent", 
                                                      icon: LucideIcons.x, 
                                                      isActive: status == TransportStatus.ABSENT, 
                                                      color: Colors.red,
                                                      onTap: () => appState.updateEmployeeStatus(emp.id, selectedWeek, TransportStatus.ABSENT)
                                                  ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Self Travel Button
                                               Expanded(
                                                 child: _StatusBtn(
                                                    label: "Self", 
                                                    icon: LucideIcons.car, 
                                                    isActive: status == TransportStatus.SELF_TRAVEL, 
                                                    color: Colors.grey,
                                                    onTap: () => appState.updateEmployeeStatus(emp.id, selectedWeek, TransportStatus.SELF_TRAVEL)
                                                 ),
                                               )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            )
      ],
    );
  }

  Color _getCompanyColor(String company) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.redAccent,
    ];
    return colors[company.hashCode.abs() % colors.length];
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
        final activeColor = color == Colors.grey ? Colors.grey[800]! : color;
        
        return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.white,
                    border: Border.all(color: isActive ? activeColor : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isActive ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0,2))] : []
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(label, style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isActive ? Colors.white : Colors.grey[600],
                            fontSize: 12
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
