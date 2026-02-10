import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';
import '../services/storage_service.dart';

class PdfExportService {
  static Future<void> generateMonthlyReport(
    DateTime month,
    List<Employee> employees,
    AppState appState,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    // Use a font that supports checkmarks if possible, or use standard ASCII

    // Prepare Data
    final monthStr = DateFormat('MMMM yyyy').format(month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = List.generate(daysInMonth, (i) => i + 1);

    // Fetch all attendance data for the month
    final storage = StorageService();
    final Map<int, Map<String, Map<String, TransportStatus>>> monthData = {};

    // Parallel fetch for speed
    await Future.wait(
      days.map((day) async {
        final date = DateTime(month.year, month.month, day);
        final data = await storage.getAttendance(date);
        monthData[day] = data;
      }),
    );

    // Header Row
    final headers = ["#", "Name", "Route", ...days.map((d) => d.toString())];

    pdf.addPage(
      pw.MultiPage(
        maxPages: 100,
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader("Monthly Attendance Check", monthStr),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: employees.map((e) {
              final row = <String>[e.serialNumber, e.name, e.pickupLocation];

              for (int day in days) {
                final dayRecords = monthData[day];
                String cellText = "";

                if (dayRecords != null && dayRecords.containsKey(e.id)) {
                  final record = dayRecords[e.id]!;
                  final p = record['pickup'] ?? TransportStatus.PENDING;
                  final d = record['dropoff'] ?? TransportStatus.PENDING;
                  cellText = _formatCompactStatus(p, d);
                }
                row.add(cellText);
              }
              return row;
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 7),
            columnWidths: {
              0: const pw.FixedColumnWidth(25), // #
              1: const pw.FixedColumnWidth(100), // Name
              2: const pw.FixedColumnWidth(60), // Route
              // Auto-distribute rest for days
              for (int i = 0; i < daysInMonth; i++)
                (i + 3): const pw.FlexColumnWidth(1),
            },
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              "Legend: O=OK/Dropped Off, A=Absent, S=Self, B=On Board, P=Pending",
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Monthly_Attendance_$monthStr',
    );
  }

  static String _formatCompactStatus(TransportStatus p, TransportStatus d) {
    String code(TransportStatus s) {
      switch (s) {
        case TransportStatus.DROPPED_OFF:
          return "O";
        case TransportStatus.ABSENT:
          return "A";
        case TransportStatus.SELF_TRAVEL:
          return "S";
        case TransportStatus.ON_BOARD:
          return "B";
        case TransportStatus.PENDING:
          return "";
      }
    }

    final pCode = code(p);
    final dCode = code(d);

    if (pCode.isEmpty && dCode.isEmpty) return "";
    if (pCode == dCode) return pCode;

    // If one is empty
    if (pCode.isEmpty) return "D:$dCode";
    if (dCode.isEmpty) return "P:$pCode";

    return "$pCode/$dCode";
  }

  static Future<void> generateWeeklyReport(
    DateTime month,
    int weekIndex,
    List<Employee> employees,
    AppState appState,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final monthStr = DateFormat('MMMM yyyy').format(month);
    final weekStart = appState.calculateDate(
      DayOfWeek.Monday,
      weekIndex,
      referenceDate: month,
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateRange =
        "${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}";

    // Prepare day headers with dates
    final dayHeaders = <String>[];
    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      final dayName = DateFormat('E').format(dayDate); // Mon, Tue...
      final dayNum = DateFormat('d').format(dayDate);
      dayHeaders.add("$dayName\n$dayNum");
    }

    pdf.addPage(
      pw.MultiPage(
        maxPages: 100,
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(
            "Weekly Attendance - Week ${weekIndex + 1}",
            "$monthStr ($dateRange)",
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ["#", "Name", "Company", "Route", ...dayHeaders],
            data: employees.map((e) {
              // Determine status for this specific week
              final statusStr = _formatCombinedStatus(e, weekIndex);

              // Create list of 7 empty strings
              final dayColumns = List<String>.filled(7, "");

              // Place status in the correct column based on employee's day
              // Assuming DayOfWeek enum order: Monday=0 ... Sunday=6
              if (e.day.index < 7) {
                dayColumns[e.day.index] = statusStr;
              }

              return [
                e.serialNumber,
                e.name,
                e.company,
                e.pickupLocation,
                ...dayColumns,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: const pw.FixedColumnWidth(30), // #
              1: const pw.FlexColumnWidth(2), // Name
              2: const pw.FlexColumnWidth(1.5), // Company
              3: const pw.FlexColumnWidth(1.5), // Route
              4: const pw.FlexColumnWidth(1), // Mon
              5: const pw.FlexColumnWidth(1), // Tue
              6: const pw.FlexColumnWidth(1), // Wed
              7: const pw.FlexColumnWidth(1), // Thu
              8: const pw.FlexColumnWidth(1), // Fri
              9: const pw.FlexColumnWidth(1), // Sat
              10: const pw.FlexColumnWidth(1), // Sun
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Weekly_Attendance_Week${weekIndex + 1}_$monthStr',
    );
  }

  static Future<void> generateDailyReport(
    DateTime date,
    int weekIndex,
    List<Employee> employees,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(date);

    DayOfWeek targetDay;
    if (date.weekday <= 7) {
      targetDay = DayOfWeek.values[date.weekday - 1];
    } else {
      targetDay = DayOfWeek.Monday; // Fallback
    }

    final dailyEmployees = employees.where((e) => e.day == targetDay).toList();

    // Sort by time
    dailyEmployees.sort((a, b) => a.time.compareTo(b.time));

    pdf.addPage(
      pw.MultiPage(
        maxPages: 100,
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader("Daily Attendance Report", dateStr),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              "#",
              "Name",
              "Company",
              "Route",
              "Time",
              "Pickup Status",
              "Dropoff Status",
            ],
            data: dailyEmployees.map((e) {
              return [
                e.serialNumber,
                e.name,
                e.company,
                e.pickupLocation,
                e.time,
                _formatSingleStatus(e.weeklyPickupStatus, weekIndex),
                _formatSingleStatus(e.weeklyDropoffStatus, weekIndex),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FixedColumnWidth(40),
              // 5 was Drop-Off
              5: const pw.FixedColumnWidth(50),
              6: const pw.FixedColumnWidth(50),
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Daily_Attendance_$dateStr',
    );
  }

  static pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  static String _formatCombinedStatus(Employee emp, int index) {
    final p = _formatSingleStatus(emp.weeklyPickupStatus, index);
    final d = _formatSingleStatus(emp.weeklyDropoffStatus, index);

    if (p.isEmpty && d.isEmpty) return "";
    if (p == d) return p; // Both same (e.g. Absent)

    // If one pending, show other?
    if (p.isEmpty) return "D: $d";
    if (d.isEmpty) return "P: $p";

    return "P: $p\nD: $d";
  }

  static String _formatSingleStatus(
    List<TransportStatus> statusList,
    int index,
  ) {
    if (index >= statusList.length) return "-";
    final status = statusList[index];
    switch (status) {
      case TransportStatus.PENDING:
        return "";
      case TransportStatus.ON_BOARD:
        return "On Board";
      case TransportStatus.DROPPED_OFF:
        return "OK";
      case TransportStatus.ABSENT:
        return "Absent";
      case TransportStatus.SELF_TRAVEL:
        return "Self";
    }
  }
}
