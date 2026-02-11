import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  final DayOfWeek selectedDay;

  const EditEmployeeScreen({
    super.key,
    this.employee,
    required this.selectedDay,
  });

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController pickupCtrl;
  late TextEditingController companyCtrl;
  late TextEditingController timeCtrl;
  late TextEditingController dropOffTimeCtrl;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;

    nameCtrl = TextEditingController(text: emp?.name ?? '');
    phoneCtrl = TextEditingController(text: emp?.phoneNumber ?? '');
    pickupCtrl = TextEditingController(text: emp?.pickupLocation ?? '');
    companyCtrl = TextEditingController(text: emp?.company ?? '');
    timeCtrl = TextEditingController(text: emp?.time ?? '08:00');
    dropOffTimeCtrl = TextEditingController(text: emp?.dropOffTime ?? '17:00');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    pickupCtrl.dispose();
    companyCtrl.dispose();
    timeCtrl.dispose();
    dropOffTimeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (timeCtrl.text.isEmpty ||
        nameCtrl.text.isEmpty ||
        pickupCtrl.text.isEmpty ||
        companyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final appState = context.read<AppState>();
    final serial =
        widget.employee?.serialNumber ?? '${appState.employees.length + 1}';

    final newEmp = Employee(
      id:
          widget.employee?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      serialNumber: serial,
      name: nameCtrl.text,
      phoneNumber: phoneCtrl.text,
      pickupLocation: pickupCtrl.text,
      company: companyCtrl.text,
      time: timeCtrl.text,
      dropOffTime: widget.employee?.dropOffTime ?? '17:00',
      day: widget.selectedDay,
      weeklyPickupStatus:
          widget.employee?.weeklyPickupStatus ??
          List.filled(5, TransportStatus.PENDING),
      weeklyDropoffStatus:
          widget.employee?.weeklyDropoffStatus ??
          List.filled(5, TransportStatus.PENDING),
      weeklyHealthChecks:
          widget.employee?.weeklyHealthChecks ?? List.filled(5, null),
      lastUpdated: DateTime.now().toIso8601String(),
    );

    appState.updateEmployee(newEmp);
    Navigator.pop(context);
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _showAddDialog(String title, Function(String) onAdd) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add $title"),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: "Enter new $title",
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.employee == null;
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        title: Text(
          isNew ? "Add Employee" : "Edit Employee",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Shift Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: timeCtrl,
                      readOnly: true,
                      decoration: _inputStyle(
                        "Pick-up Time (HH:MM)",
                        FontAwesomeIcons.clock,
                      ),
                      onTap: () async {
                        TimeOfDay initialTime = TimeOfDay(hour: 8, minute: 0);
                        if (timeCtrl.text.isNotEmpty) {
                          try {
                            final parts = timeCtrl.text.split(':');
                            if (parts.length == 2) {
                              initialTime = TimeOfDay(
                                hour: int.parse(parts[0]),
                                minute: int.parse(parts[1]),
                              );
                            }
                          } catch (_) {}
                        }

                        final selected = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );

                        if (selected != null) {
                          final hour = selected.hour.toString().padLeft(2, '0');
                          final minute = selected.minute.toString().padLeft(
                            2,
                            '0',
                          );
                          setState(() {
                            timeCtrl.text = "$hour:$minute";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputStyle(
                        "Passenger Name",
                        FontAwesomeIcons.user,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputStyle(
                        "Phone Number",
                        FontAwesomeIcons.phone,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value:
                                appState.pickupLocations.contains(
                                  pickupCtrl.text,
                                )
                                ? pickupCtrl.text
                                : null,
                            decoration: _inputStyle(
                              "Pickup Location",
                              FontAwesomeIcons.locationDot,
                            ),
                            items: appState.pickupLocations
                                .map(
                                  (loc) => DropdownMenuItem(
                                    value: loc,
                                    child: Text(loc),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => pickupCtrl.text = val ?? '',
                            icon: const Icon(
                              FontAwesomeIcons.chevronDown,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              _showAddDialog("Pickup Location", (val) {
                                appState.addPickupLocation(val);
                                setState(() {
                                  pickupCtrl.text = val;
                                });
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: appState.companies.contains(companyCtrl.text)
                                ? companyCtrl.text
                                : null,
                            decoration: _inputStyle(
                              "Company",
                              FontAwesomeIcons.building,
                            ),
                            items: appState.companies
                                .map(
                                  (com) => DropdownMenuItem(
                                    value: com,
                                    child: Text(com),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => companyCtrl.text = val ?? '',
                            icon: const Icon(
                              FontAwesomeIcons.chevronDown,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              _showAddDialog("Company", (val) {
                                appState.addCompany(val);
                                setState(() {
                                  companyCtrl.text = val;
                                });
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(FontAwesomeIcons.check, size: 18),
                label: const Text(
                  "Save Employee",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
