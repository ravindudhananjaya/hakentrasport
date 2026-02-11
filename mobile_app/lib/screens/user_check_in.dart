import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';
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

    return Column(
      children: [
        // Controls
        // 1. Month Header & Print
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(SolarIconsOutline.altArrowLeft),
                    onPressed: () => _changeMonth(-1),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthNames[selectedMonth.month - 1],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "${selectedMonth.year}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(SolarIconsOutline.altArrowRight),
                    onPressed: () => _changeMonth(1),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),

              // Print Button
              FilledButton.tonalIcon(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Select Report Type"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(SolarIconsOutline.calendar),
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
                            leading: const Icon(SolarIconsOutline.calendarDate),
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
                            leading: const Icon(SolarIconsOutline.clockCircle),
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
                icon: const Icon(SolarIconsOutline.printer, size: 18),
                label: const Text("Print"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  foregroundColor: Colors.blue,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Week Selector (Segmented Look)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(5, (index) {
              final isSelected = index == selectedWeek;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => selectedWeek = index),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).dividerColor,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      "Week ${index + 1}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        // 3. Day Selector (Horizontal Values)
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DayOfWeek.values.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 12),
            itemBuilder: (ctx, index) {
              final day = DayOfWeek.values[index];
              final isSelected = day == selectedDay;

              // Calculate date for this day in the current week/month view if needed
              // For simplicity, just show Day Name + generic indicator

              return InkWell(
                onTap: () => setState(() => selectedDay = day),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Theme.of(context).dividerColor,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.name.substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // 4. Search Bar & Date Info Row
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search passenger...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[600]
                          : Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      SolarIconsOutline.magnifier,
                      size: 20,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (val) => setState(() => searchTerm = val),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Date Display (Subtle)
        Builder(
          builder: (context) {
            final date = appState.calculateDate(
              selectedDay,
              selectedWeek,
              referenceDate: selectedMonth,
            );
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
                "${selectedDay.name}, ${months[date.month - 1]} ${date.day}, ${date.year}";

            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        // 1. Update Month
                        if (picked.month != selectedMonth.month ||
                            picked.year != selectedMonth.year) {
                          selectedMonth = DateTime(
                            picked.year,
                            picked.month,
                            1,
                          );
                          context.read<AppState>().loadAttendanceForMonth(
                            selectedMonth,
                          );
                        }

                        // 2. Update Day
                        // picked.weekday: 1=Mon, 7=Sun
                        if (picked.weekday <= 7) {
                          selectedDay = DayOfWeek.values[picked.weekday - 1];
                        }

                        // 3. Update Week
                        // This is tricky because weeks are 0-4 based on day of month.
                        // Ideally, we reverse the logic: (day - 1) ~/ 7
                        selectedWeek = (picked.day - 1) ~/ 7;
                        if (selectedWeek > 4)
                          selectedWeek = 4; // Cap at 5 weeks
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          SolarIconsOutline.calendar,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
                          SolarIconsOutline.clockCircle,
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
                                                            SolarIconsOutline
                                                                .phone,
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
                                                      SolarIconsOutline
                                                          .mapPoint,
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
                                                      SolarIconsOutline
                                                          .buildings,
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
                                              icon:
                                                  SolarIconsOutline.checkCircle,
                                              isActive:
                                                  status ==
                                                  TransportStatus.DROPPED_OFF,
                                              color: Colors.green,
                                              onTap: () async {
                                                if (isPickup) {
                                                  _showHealthCheckDialog(
                                                    context,
                                                    emp,
                                                    appState,
                                                    selectedWeek,
                                                    isPickup,
                                                  );
                                                } else {
                                                  // Drop-off: Direct save without health check
                                                  await appState
                                                      .saveAttendanceWithHealth(
                                                        emp.id,
                                                        selectedWeek,
                                                        TransportStatus
                                                            .DROPPED_OFF,
                                                        null,
                                                        null,
                                                        isPickup: isPickup,
                                                      );
                                                  appState.updateEmployeeStatus(
                                                    emp.id,
                                                    selectedWeek,
                                                    TransportStatus.DROPPED_OFF,
                                                    isPickup: isPickup,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Marked as Dropped Off: ${emp.name}',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                      duration: const Duration(
                                                        seconds: 1,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _StatusBtn(
                                              label: "Absent",
                                              icon:
                                                  SolarIconsOutline.closeCircle,
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
                                              icon: SolarIconsOutline.bus,
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
                  SolarIconsOutline.heartPulse,
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
                      icon: SolarIconsOutline.smileCircle,
                      color: Colors.green,
                      isSelected: selectedHealthCondition == 'Good',
                      onTap: () =>
                          setState(() => selectedHealthCondition = 'Good'),
                    ),
                    _HealthOptionChip(
                      label: 'Not Good',
                      icon: SolarIconsOutline.sadSquare,
                      color: Colors.orange,
                      isSelected: selectedHealthCondition == 'Not Good',
                      onTap: () =>
                          setState(() => selectedHealthCondition = 'Not Good'),
                    ),
                    _HealthOptionChip(
                      label: 'Diarrhea',
                      icon: SolarIconsOutline.dangerCircle,
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
                      SolarIconsOutline.thermometer,
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
