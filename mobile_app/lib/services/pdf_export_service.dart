import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';

class PdfExportService {
  static Future<void> generateAndPrint(
    DateTime month,
    List<Employee> employees,
    AppState appState, // Need appState to calculate dates
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Prepare Data
    final monthStr = DateFormat('MMMM yyyy').format(month);

    // Calculate week dates for headers
    final weekDates = <String>[];
    for (int i = 0; i < 5; i++) {
      // We need a representative date to show "Week 1 (Jan 5)"
      // Simple heuristic: Take the Monday of that week?
      // Or just show "Week 1", "Week 2"?
      // User requested "add date" in list, so PDF should probably have specific dates.

      // Let's rely on a reliable generic date.
      // We can't know the exact date for *every* employee in the header
      // because employees have different days (Mon vs Wed).
      // Best approach: "Week 1", "Week 2"...
      // OR: "Week of Jan 5"

      // Let's use Monday as the anchor for the column header
      final mondayDate = appState.calculateDate(
        DayOfWeek.Monday,
        i,
        referenceDate: month,
      );
      weekDates.add("${mondayDate.month}/${mondayDate.day}");
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Landscape for more width
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Haken Transport - Monthly Attendance",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(monthStr, style: const pw.TextStyle(fontSize: 18)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              "#",
              "Name",
              "Company",
              "Route",
              "Week 1\n(${weekDates[0]})",
              "Week 2\n(${weekDates[1]})",
              "Week 3\n(${weekDates[2]})",
              "Week 4\n(${weekDates[3]})",
              "Week 5\n(${weekDates[4]})",
            ],
            data: employees.map((e) {
              return [
                e.serialNumber,
                e.name,
                e.company,
                e.pickupLocation,
                _formatWeekData(e, 0),
                _formatWeekData(e, 1),
                _formatWeekData(e, 2),
                _formatWeekData(e, 3),
                _formatWeekData(e, 4),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Attendance_$monthStr',
    );
  }

  static String _formatWeekData(Employee employee, int weekIndex) {
    final status = _formatStatus(employee.weeklyStatus, weekIndex);

    // Get health check data if available
    if (weekIndex < employee.weeklyHealthChecks.length) {
      final healthCheck = employee.weeklyHealthChecks[weekIndex];
      if (healthCheck != null) {
        // Format: Status\nCondition\nTemp
        final condition = _formatHealthCondition(healthCheck.healthCondition);
        final temp = "${healthCheck.temperature.toStringAsFixed(1)}°C";
        return "$status\n$condition\n$temp";
      }
    }

    return status;
  }

  static String _formatHealthCondition(String condition) {
    switch (condition) {
      case "Good":
        return "Good";
      case "Not Good":
        return "Not Good";
      case "Diarrhea":
        return "Diarrhea";
      default:
        return condition;
    }
  }

  static String _formatStatus(List<TransportStatus> statusList, int index) {
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
