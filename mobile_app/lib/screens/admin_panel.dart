
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';


class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  DayOfWeek selectedDay = DayOfWeek.Monday;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final data = appState.employees.where((e) => e.day == selectedDay).toList();
    data.sort((a,b) => a.time.compareTo(b.time));

    return Column(
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
        
        // Header Actions
        Row(
            children: [
                Expanded(child: Text("Schedule: ${selectedDay.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ElevatedButton.icon(
                    onPressed: () => _showEditDialog(context, null, appState),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text("Add Row"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                )
            ],
        ),
        const SizedBox(height: 16),

        // List
        if (data.isEmpty)
             const Padding(
               padding: EdgeInsets.all(32.0),
               child: Center(child: Text("No shifts scheduled.", style: TextStyle(color: Colors.grey))),
             )
        else
            ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: data.length,
                itemBuilder: (ctx, index) {
                    final emp = data[index];
                    return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                                children: [
                                    Container(
                                        width: 4, height: 40,
                                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text(emp.time, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                                Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                Text("${emp.pickupLocation} • ${emp.company}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                            ],
                                        ),
                                    ),
                                    IconButton(
                                        icon: const Icon(LucideIcons.edit2, size: 18, color: Colors.blue),
                                        onPressed: () => _showEditDialog(context, emp, appState),
                                    ),
                                    IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                        onPressed: () {
                                            if(data.length < 2) {
                                               // prevent clearing all maybe? nah allowed.
                                            }
                                            // confirm delete
                                            showDialog(context: context, builder: (ctx) => AlertDialog(
                                                title: const Text("Delete?"),
                                                content: const Text("Are you sure you want to delete this row?"),
                                                actions: [
                                                    TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
                                                    TextButton(
                                                        onPressed: () {
                                                            appState.deleteEmployee(emp.id);
                                                            Navigator.pop(ctx);
                                                        }, 
                                                        child: const Text("Delete", style: TextStyle(color: Colors.red))
                                                    )
                                                ],
                                            ));
                                        },
                                    )
                                ],
                            ),
                        ),
                    );
                }
            )
      ],
    );
  }

  void _showEditDialog(BuildContext context, Employee? employee, AppState appState) {
    final isNew = employee == null;
    
    // Controllers
    final nameCtrl = TextEditingController(text: employee?.name ?? '');
    final pickupCtrl = TextEditingController(text: employee?.pickupLocation ?? '');
    final companyCtrl = TextEditingController(text: employee?.company ?? '');
    final timeCtrl = TextEditingController(text: employee?.time ?? '08:00');
    final serialCtrl = TextEditingController(text: employee?.serialNumber ?? '${appState.employees.length + 1}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? "Add Employee" : "Edit Employee"),
        content: SingleChildScrollView(
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                 TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "Time (HH:MM)")),
                 TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
                 TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: "Serial #")),
                 TextField(controller: pickupCtrl, decoration: const InputDecoration(labelText: "Pickup Location")),
                 TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: "Company")),
             ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
               // Validation (basic)
               if(timeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;

               final newEmp = Employee(
                   id: employee?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), // simple ID gen
                   serialNumber: serialCtrl.text,
                   name: nameCtrl.text,
                   pickupLocation: pickupCtrl.text,
                   company: companyCtrl.text,
                   time: timeCtrl.text,
                   day: selectedDay,
                   weeklyStatus: employee?.weeklyStatus ?? List.filled(5, TransportStatus.PENDING),
                   lastUpdated: DateTime.now().toIso8601String()
               );
               
               appState.updateEmployee(newEmp);
               Navigator.pop(ctx);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}
