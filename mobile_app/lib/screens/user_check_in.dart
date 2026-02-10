import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';
import '../services/pdf_export_service.dart';

class UserCheckIn extends StatefulWidget {
  const UserCheckIn({super.key});

  @override
  State<UserCheckIn> createState() => _UserCheckInState();
}

class _UserCheckInState extends State<UserCheckIn> {
  DayOfWeek selectedDay = DayOfWeek.Monday; // Default
  DateTime selectedMonth = DateTime.now(); // Default to current month
  int selectedWeek = 0;
  String searchTerm = '';
  bool isPickup = true;

  @override
  void initState() {
    super.initState();
    // Default to today's day of week
    final now = DateTime.now();
    final nowDay = now.weekday; // 1 = Mon, 7 = Sun
    if (nowDay <= 7) {
      selectedDay = DayOfWeek.values[nowDay - 1];
    }

    // Default to current week index (0-based) based on day of month
    selectedWeek = (now.day - 1) ~/ 7;
    // selectedMonth is already initialized to now
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      // Calculate new month
      final newMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + monthsToAdd,
        1,
      );
      selectedMonth = newMonth;
      // Optionally reset week? Let's keep week if possible, or reset if out of bounds?
      // Week 0-4 is generic. Keep it.
    });
    // Reload attendance for this new month
    // We need access to appState here, but we are inside setState.
    // Best to call this in the UI callback or after build frame?
    // Accessing context.read<AppState>() is safe here? Yes.
    context.read<AppState>().loadAttendanceForMonth(selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final data = appState.employees;

    // Filter Logic
    // Filter Logic
    final filtered = data.filter((e) => e.day == selectedDay).toList();
    filtered.sort((a, b) => a.time.compareTo(b.time));

    final searchFiltered = searchTerm.isEmpty
        ? filtered
        : filtered
              .where(
                (e) =>
                    e.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                    e.serialNumber.contains(searchTerm),
              )
              .toList();

    // Grouping Logic
    final groups = <String, List<Employee>>{};

    for (var e in searchFiltered) {
      final timeStr = e.time;
      final hour = timeStr.split(':')[0];
      final key = "$hour:00 - $hour:59";
      groups.putIfAbsent(key, () => []).add(e);
    }
    final sortedKeys = groups.keys.toList()..sort();

    // Date formatting for Month Selector
    final monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    final monthStr =
        "${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}";

    return Column(
      children: [
        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              // Month Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        monthStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.printer, color: Colors.blue),
                    tooltip: "Export PDF",
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Select Report Type"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(LucideIcons.calendar),
                                title: const Text("Monthly Report"),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await PdfExportService.generateMonthlyReport(
                                    selectedMonth,
                                    data,
                                    context.read<AppState>(),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(LucideIcons.calendarDays),
                                title: Text(
                                  "Weekly Report (Week ${selectedWeek + 1})",
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await PdfExportService.generateWeeklyReport(
                                    selectedMonth,
                                    selectedWeek,
                                    data,
                                    context.read<AppState>(),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(LucideIcons.clock),
                                title: const Text("Daily Report"),
                                subtitle: Text(
                                  "${selectedDay.name} of Week ${selectedWeek + 1}",
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  // Calculate specific date for daily report
                                  final date = context
                                      .read<AppState>()
                                      .calculateDate(
                                        selectedDay,
                                        selectedWeek,
                                        referenceDate: selectedMonth,
                                      );
                                  await PdfExportService.generateDailyReport(
                                    date,
                                    selectedWeek,
                                    data,
                                  );
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

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
                        backgroundColor: isSelected
                            ? const Color(0xFF1E293B)
                            : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        onPressed: () => setState(() => selectedDay = day),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Align left on mobile
                  children: List.generate(5, (index) {
                    final isSelected = index == selectedWeek;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedWeek = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            "WEEK ${index + 1}",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
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
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 20,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (val) => setState(() => searchTerm = val),
              ),

              const SizedBox(height: 12),

              // Date Display
              Builder(
                builder: (context) {
                  final date = appState.calculateDate(
                    selectedDay,
                    selectedWeek,
                    referenceDate: selectedMonth, // Pass selected month
                  );
                  // Simple Format: "Tuesday, Jan 20"
                  // Or standard: YYYY-MM-DD
                  // Let's do readable
                  final months = [
                    "Jan",
                    "Feb",
                    "Mar",
                    "Apr",
                    "May",
                    "Jun",
                    "Jul",
                    "Aug",
                    "Sep",
                    "Oct",
                    "Nov",
                    "Dec",
                  ];
                  final dateStr =
                      "${selectedDay.name}, ${months[date.month - 1]} ${date.day}";

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Viewing Date: ",
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Toggle Switch (Slider)
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isPickup
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5 - 32,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isPickup
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isPickup = true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          "Pickup",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isPickup = false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          "Drop-off",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // List
        if (searchFiltered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                "No passengers found.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
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
                        const Icon(
                          LucideIcons.clock,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPickup ? "$key - Pickup" : "$key - Drop-off",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${employees.length} Pax",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Items
                  ...employees.map((emp) {
                    final companyColor = _getCompanyColor(emp.company);
                    final statusList = isPickup
                        ? emp.weeklyPickupStatus
                        : emp.weeklyDropoffStatus;
                    final status = statusList.length > selectedWeek
                        ? statusList[selectedWeek]
                        : TransportStatus.PENDING;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Time Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              emp.time,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                                color: Colors.blue.shade800,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        emp.name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      color: Colors.grey[100],
                                                      child: Text(
                                                        "#${emp.serialNumber}",
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                    if (emp
                                                        .phoneNumber
                                                        .isNotEmpty) ...[
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () async {
                                                          final cleanNumber =
                                                              emp.phoneNumber
                                                                  .replaceAll(
                                                                    RegExp(
                                                                      r'\s+|-',
                                                                    ),
                                                                    '',
                                                                  );
                                                          final Uri launchUri =
                                                              Uri(
                                                                scheme: 'tel',
                                                                path:
                                                                    cleanNumber,
                                                              );
                                                          if (await canLaunchUrl(
                                                            launchUri,
                                                          )) {
                                                            await launchUrl(
                                                              launchUri,
                                                            );
                                                          } else {
                                                            await launchUrl(
                                                              launchUri,
                                                              mode: LaunchMode
                                                                  .externalApplication,
                                                            );
                                                          }
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                6,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: Colors
                                                                    .green
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: const Icon(
                                                            LucideIcons.phone,
                                                            size: 18,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      LucideIcons.mapPin,
                                                      size: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        emp.pickupLocation,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      LucideIcons.building,
                                                      size: 12,
                                                      color: companyColor
                                                          .withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      emp.company,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: companyColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
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
                                              isActive:
                                                  status ==
                                                  TransportStatus.DROPPED_OFF,
                                              color: Colors.green,
                                              onTap: () =>
                                                  _showHealthCheckDialog(
                                                    context,
                                                    emp,
                                                    appState,
                                                    selectedWeek,
                                                    isPickup,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _StatusBtn(
                                              label: "Absent",
                                              icon: LucideIcons.x,
                                              isActive:
                                                  status ==
                                                  TransportStatus.ABSENT,
                                              color: Colors.red,
                                              onTap: () =>
                                                  appState.updateEmployeeStatus(
                                                    emp.id,
                                                    selectedWeek,
                                                    TransportStatus.ABSENT,
                                                    isPickup: isPickup,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Self Travel Button
                                          Expanded(
                                            child: _StatusBtn(
                                              label: "Self",
                                              icon: LucideIcons.car,
                                              isActive:
                                                  status ==
                                                  TransportStatus.SELF_TRAVEL,
                                              color: Colors.grey,
                                              onTap: () =>
                                                  appState.updateEmployeeStatus(
                                                    emp.id,
                                                    selectedWeek,
                                                    TransportStatus.SELF_TRAVEL,
                                                    isPickup: isPickup,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
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
          ),
      ],
    );
  }

  void _showHealthCheckDialog(
    BuildContext context,
    Employee emp,
    AppState appState,
    int selectedWeek,
    bool isPickup,
  ) {
    String? selectedHealthCondition;
    final temperatureController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.heartPulse,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Health Check',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver name
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emp.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Question 1: Health Condition
                Text(
                  '1. Health Condition',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HealthOptionChip(
                      label: 'Good',
                      icon: LucideIcons.smile,
                      color: Colors.green,
                      isSelected: selectedHealthCondition == 'Good',
                      onTap: () =>
                          setState(() => selectedHealthCondition = 'Good'),
                    ),
                    _HealthOptionChip(
                      label: 'Not Good',
                      icon: LucideIcons.frown,
                      color: Colors.orange,
                      isSelected: selectedHealthCondition == 'Not Good',
                      onTap: () =>
                          setState(() => selectedHealthCondition = 'Not Good'),
                    ),
                    _HealthOptionChip(
                      label: 'Diarrhea',
                      icon: LucideIcons.alertCircle,
                      color: Colors.red,
                      isSelected: selectedHealthCondition == 'Diarrhea',
                      onTap: () =>
                          setState(() => selectedHealthCondition = 'Diarrhea'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Question 2: Body Temperature
                Text(
                  '2. Body Temperature',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: temperatureController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter temperature',
                    suffixText: '°C',
                    suffixStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.thermometer,
                      color: Colors.blue,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
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
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Normal range: 36.1°C - 37.2°C',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Parse temperature if provided
                double? temperature;
                if (temperatureController.text.trim().isNotEmpty) {
                  temperature = double.tryParse(
                    temperatureController.text.trim(),
                  );
                  if (temperature == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid temperature'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                }

                // Save the context before async operations
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final employeeName = emp.name;

                // Close dialog
                Navigator.of(dialogContext).pop();

                // Save attendance with health check data (can be null)
                await appState.saveAttendanceWithHealth(
                  emp.id,
                  selectedWeek,
                  TransportStatus.DROPPED_OFF,
                  selectedHealthCondition,
                  temperature,
                  isPickup: isPickup,
                );

                // Update local status
                appState.updateEmployeeStatus(
                  emp.id,
                  selectedWeek,
                  TransportStatus.DROPPED_OFF,
                  isPickup: isPickup,
                );

                // Show success message with health info (using saved messenger)
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: (() {
                      String msg = 'Attendance marked for $employeeName';
                      if (selectedHealthCondition != null ||
                          temperature != null) {
                        msg += '\n';
                        if (selectedHealthCondition != null) {
                          msg += 'Condition: $selectedHealthCondition';
                        }
                        if (temperature != null) {
                          if (selectedHealthCondition != null) msg += ' | ';
                          msg += 'Temp: ${temperature.toStringAsFixed(1)}°C';
                        }
                      }
                      return Text(msg);
                    })(),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
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

  const _StatusBtn({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

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
          color: isActive ? activeColor : Theme.of(context).cardColor,
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension Filter<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);
}

class _HealthOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _HealthOptionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? color
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? color
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
