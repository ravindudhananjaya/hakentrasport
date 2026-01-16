
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';
import 'edit_employee_screen.dart';


class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  DayOfWeek selectedDay = DayOfWeek.Monday;

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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final data = appState.employees.where((e) => e.day == selectedDay).toList();
    data.sort((a,b) => a.time.compareTo(b.time));

    // Grouping Logic
    final groups = <String, List<Employee>>{};
    for(var e in data) {
        final hour = e.time.split(':')[0];
        final key = "$hour:00 - $hour:59";
        groups.putIfAbsent(key, () => []).add(e);
    }
    final sortedKeys = groups.keys.toList()..sort();

    return Column(
      children: [
        // Day Selector
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: DayOfWeek.values.length,
            separatorBuilder: (_,__) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = DayOfWeek.values[index];
              final isSelected = day == selectedDay;
              
              return GestureDetector(
                onTap: () => setState(() => selectedDay = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                    ] : [],
                  ),
                  child: Text(
                    day.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade600
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Header Actions
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Schedule", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    Text(selectedDay.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => EditEmployeeScreen(selectedDay: selectedDay))
                    ),
                    icon: const Icon(FontAwesomeIcons.plus, size: 14),
                    label: const Text("Add Row"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                )
            ],
        ),
        const SizedBox(height: 16),

        // List
        if (data.isEmpty)
             Padding(
               padding: const EdgeInsets.all(32.0),
               child: Column(
                 children: [
                   Icon(FontAwesomeIcons.calendarXmark, size: 48, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   const Text("No shifts scheduled.", style: TextStyle(color: Colors.grey)),
                 ],
               ),
             )
        else
            ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
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
                                    child: InkWell(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => EditEmployeeScreen(employee: emp, selectedDay: selectedDay))
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Color Strip
                                            Container(width: 6, color: companyColor),
                                            
                                            Expanded(
                                              child: Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Row(
                                                      children: [
                                                          // Time Pill
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.blue.shade50,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              emp.time, 
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold, 
                                                                fontFamily: 'monospace',
                                                                color: Colors.blue.shade800
                                                              )
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                              child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                      Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                      const SizedBox(height: 4),
                                                                      Row(
                                                                        children: [
                                                                          Icon(FontAwesomeIcons.locationDot, size: 10, color: Colors.grey[400]),
                                                                          const SizedBox(width: 4),
                                                                          Expanded(child: Text(emp.pickupLocation, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(height: 4),
                                                                      Row(
                                                                        children: [
                                                                          Icon(FontAwesomeIcons.building, size: 10, color: companyColor.withOpacity(0.7)),
                                                                          const SizedBox(width: 4),
                                                                          Expanded(child: Text(emp.company, style: TextStyle(fontSize: 12, color: companyColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                                                        ],
                                                                      ),
                                                                  ],
                                                              ),
                                                          ),
                                                          
                                                          // Actions
                                                          Row(
                                                            children: [
                                                              // Edit Button
                                                              Container(
                                                                width: 36, height: 36,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.grey[50], 
                                                                  borderRadius: BorderRadius.circular(8)
                                                                ),
                                                                child: IconButton(
                                                                  icon: const Icon(FontAwesomeIcons.pen, size: 14, color: Colors.blue),
                                                                  onPressed: () => Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(builder: (_) => EditEmployeeScreen(employee: emp, selectedDay: selectedDay))
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              // Delete Button
                                                              Container(
                                                                width: 36, height: 36,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.red.withOpacity(0.05), 
                                                                  borderRadius: BorderRadius.circular(8)
                                                                ),
                                                                child: IconButton(
                                                                    icon: const Icon(FontAwesomeIcons.trashCan, size: 14, color: Colors.red),
                                                                    onPressed: () {
                                                                        showDialog(context: context, builder: (ctx) => AlertDialog(
                                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                            title: const Row(
                                                                              children: [
                                                                                Icon(FontAwesomeIcons.triangleExclamation, color: Colors.orange, size: 20),
                                                                                SizedBox(width: 8),
                                                                                Text("Delete Entry?"),
                                                                              ],
                                                                            ),
                                                                            content: Text("Are you sure you want to delete ${emp.name}?"),
                                                                            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                                            actions: [
                                                                                TextButton(
                                                                                  onPressed: ()=>Navigator.pop(ctx), 
                                                                                  child: const Text("Cancel", style: TextStyle(color: Colors.grey))
                                                                                ),
                                                                                ElevatedButton.icon(
                                                                                    onPressed: () {
                                                                                        appState.deleteEmployee(emp.id);
                                                                                        Navigator.pop(ctx);
                                                                                    }, 
                                                                                    icon: const Icon(FontAwesomeIcons.trash, size: 14),
                                                                                    label: const Text("Delete"),
                                                                                    style: ElevatedButton.styleFrom(
                                                                                      backgroundColor: Colors.red,
                                                                                      foregroundColor: Colors.white,
                                                                                      elevation: 0,
                                                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                                                                    ),
                                                                                )
                                                                            ],
                                                                        ));
                                                                    },
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
                                    ),
                                );
                        }),
                      ],
                    );
                }
            )




      ],
    );
  }
}
