import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/firebase_service.dart';
import 'day_detail_screen.dart';

class TimetableScreen extends StatefulWidget {
  final String semesterId;
  final String semesterName;
  final String divisionId;
  final String divisionName;

  const TimetableScreen({
    super.key,
    required this.semesterId,
    required this.semesterName,
    required this.divisionId,
    required this.divisionName,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<String> _days = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> _dayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  Future<void> _loadDays() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final days = await _firebaseService.getDaysForSemesterAndDivision(
        widget.semesterId,
        widget.divisionId,
      );
      setState(() {
        _days = days;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load timetable: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.semesterName} • ${widget.divisionName}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: _exportWeeklyTimetableAsPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDays,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _days.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No timetable found for this semester & division.\n\nAsk your partner to add timetable data in Firebase Console under "timetables/{semesterId}/{divisionId}".',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDays,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDays,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _days.map((day) {
                          return DayTile(
                            day: day,
                            semesterId: widget.semesterId,
                            divisionId: widget.divisionId,
                            divisionName: widget.divisionName,
                          );
                        }).toList(),
                      ),
                    ),
    );
  }

  Future<void> _exportWeeklyTimetableAsPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final timetable = await _firebaseService.getTimetableForSemesterAndDivision(
        widget.semesterId,
        widget.divisionId,
      );

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => pw.Text(
            'UniPlan Timetable',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          build: (context) {
            return [
              pw.SizedBox(height: 8),
              pw.Text(
                '${widget.semesterName} • ${widget.divisionName}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 16),
              for (final day in _dayOrder) ...[
                pw.Text(
                  day,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                if ((timetable[day] ?? []).isEmpty)
                  pw.Text('No classes')
                else
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.5,
                    ),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(2),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(1.5),
                      4: pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Time'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Subject'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Teacher'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Room'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Type'),
                          ),
                        ],
                      ),
                      for (final c in (timetable[day] ?? []))
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(c.time),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(c.subject),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(c.teacher),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(c.room ?? 'TBA'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(c.type),
                            ),
                          ],
                        ),
                    ],
                  ),
                pw.SizedBox(height: 18),
              ],
            ];
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'UniPlan_${widget.semesterId}_${widget.divisionId}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class DayTile extends StatelessWidget {
  final String day;
  final String semesterId;
  final String divisionId;
  final String divisionName;

  const DayTile({
    super.key,
    required this.day,
    required this.semesterId,
    required this.divisionId,
    required this.divisionName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(day),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailScreen(
                day: day,
                semesterId: semesterId,
                divisionId: divisionId,
                divisionName: divisionName,
              ),
            ),
          );
        },
      ),
    );
  }
}
