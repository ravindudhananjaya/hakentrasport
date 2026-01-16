import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';
import '../constants.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  final DayOfWeek selectedDay;

  const EditEmployeeScreen({super.key, this.employee, required this.selectedDay});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController pickupCtrl;
  late TextEditingController companyCtrl;
  late TextEditingController timeCtrl;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    
    nameCtrl = TextEditingController(text: emp?.name ?? '');
    pickupCtrl = TextEditingController(text: emp?.pickupLocation ?? '');
    companyCtrl = TextEditingController(text: emp?.company ?? '');
    timeCtrl = TextEditingController(text: emp?.time ?? '08:00');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    pickupCtrl.dispose();
    companyCtrl.dispose();
    timeCtrl.dispose();
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
        )
      );
      return;
    }

    final appState = context.read<AppState>();
    final serial = widget.employee?.serialNumber ?? '${appState.employees.length + 1}';
    
    final newEmp = Employee(
        id: widget.employee?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        serialNumber: serial,
        name: nameCtrl.text,
        pickupLocation: pickupCtrl.text,
        company: companyCtrl.text,
        time: timeCtrl.text,
        day: widget.selectedDay,
        weeklyStatus: widget.employee?.weeklyStatus ?? List.filled(5, TransportStatus.PENDING),
        lastUpdated: DateTime.now().toIso8601String()
    );
    
    appState.updateEmployee(newEmp);
    Navigator.pop(context);
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.employee == null;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          isNew ? "Add Employee" : "Edit Employee",
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                 side: BorderSide(color: Colors.grey.shade200)
               ),
               color: Colors.white,
               child: Padding(
                 padding: const EdgeInsets.all(24.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text("Shift Details", style: TextStyle(
                       fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue
                     )),
                     const SizedBox(height: 24),
                     TextField(
                       controller: timeCtrl, 
                       keyboardType: TextInputType.datetime,
                       decoration: _inputStyle("Pick-up Time (HH:MM)", FontAwesomeIcons.clock)
                     ),
                     const SizedBox(height: 20),
                     TextField(
                       controller: nameCtrl, 
                       textCapitalization: TextCapitalization.words,
                       decoration: _inputStyle("Passenger Name", FontAwesomeIcons.user)
                     ),
                     const SizedBox(height: 20),
                     DropdownButtonFormField<String>(
                       value: PICKUP_LOCATIONS.contains(pickupCtrl.text) ? pickupCtrl.text : null,
                       decoration: _inputStyle("Pickup Location", FontAwesomeIcons.locationDot),
                       items: PICKUP_LOCATIONS.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                       onChanged: (val) => pickupCtrl.text = val ?? '',
                       icon: const Icon(FontAwesomeIcons.chevronDown, size: 16),
                     ),
                     const SizedBox(height: 20),
                     DropdownButtonFormField<String>(
                       value: COMPANIES.contains(companyCtrl.text) ? companyCtrl.text : null,
                       decoration: _inputStyle("Company", FontAwesomeIcons.building),
                       items: COMPANIES.map((com) => DropdownMenuItem(value: com, child: Text(com))).toList(),
                       onChanged: (val) => companyCtrl.text = val ?? '',
                       icon: const Icon(FontAwesomeIcons.chevronDown, size: 16),
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
                 label: const Text("Save Employee", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Theme.of(context).primaryColor,
                   foregroundColor: Colors.white,
                   elevation: 2,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
               ),
             )
          ],
        ),
      ),
    );
  }
}
