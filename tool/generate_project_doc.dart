import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final doc = pw.Document();

  final titleStyle = pw.TextStyle(
    fontSize: 20,
    fontWeight: pw.FontWeight.bold,
  );
  final hStyle = pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
  );
  final pStyle = const pw.TextStyle(fontSize: 11);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Text('UniPlan — Timetable Scheduling Mobile App', style: titleStyle),
        pw.SizedBox(height: 6),
        pw.Text(
          'Project Document (Definition • Requirements • Tools & Tech)',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 18),

        pw.Text('1) Project Definition', style: hStyle),
        pw.SizedBox(height: 6),
        pw.Text(
          'UniPlan is a professional timetable scheduling mobile application for universities. '
          'It provides a centralized, role-based system for managing and consuming academic schedules. '
          'The app supports Students, Faculty, and Admin users with different dashboards and permissions. '
          'Admins maintain timetable data and publish announcements, while students view daily/weekly schedules, '
          'receive updates, and access the app even with limited connectivity through offline support.\n\n'
          'Objectives:\n'
          '- Replace manual timetable sharing (PDF/WhatsApp/notice boards)\n'
          '- Provide always-updated timetable in a clean, modern UI\n'
          '- Admin-controlled scheduling with validation to prevent conflicts\n'
          '- Better UX with notifications, offline access, and export/share',
          style: pStyle,
        ),
        pw.SizedBox(height: 14),

        pw.Text('2) Major Functional Requirements', style: hStyle),
        pw.SizedBox(height: 6),
        pw.Text(
          'A) Authentication & Role Management\n'
          '- Email/password login using Firebase Authentication\n'
          '- Role-based routing after login (Student / Faculty / Admin)\n'
          '- In-app student registration creates Auth user + /users/{uid} profile with role + semester/division\n\n'
          'B) Student Features\n'
          '- Today’s classes (subject, time, teacher, room)\n'
          '- Full timetable (semester + division selection, day-wise view)\n'
          '- Notifications panel (pin important announcements, delete/hide per student, badge count)\n'
          '- Export weekly timetable as PDF and share\n'
          '- Offline support (local caching + offline banner)\n\n'
          'C) Admin Features\n'
          '- Timetable CRUD (add/update/delete class slots)\n'
          '- Validation to prevent conflicts:\n'
          '  • Same teacher cannot be booked in two places at same time\n'
          '  • Same room cannot be double-booked at same time\n'
          '  • Same class (semester+division) cannot have two lectures at same time\n'
          '- Room dropdown from backend + show available rooms for selected slot\n'
          '- Show available time slots (teacher-free + room-available)\n'
          '- Weekly subject limits: max 4 lectures/week + 1 lab/week per subject (prevent save if exceeded)\n\n'
          'D) Data & Backend\n'
          '- Timetable: /timetables/{semesterId}/{divisionId}/{day}/{time} → {subject, teacher, room, type}\n'
          '- Reference data: /subjects, /teachers, /rooms, /semesters, /divisions\n'
          '- Announcements: /announcements (admin messages), /userAnnouncements (pin/delete per user)',
          style: pStyle,
        ),
        pw.SizedBox(height: 14),

        pw.Text('3) Tools and Technology Required', style: hStyle),
        pw.SizedBox(height: 6),
        pw.Text(
          'Frontend\n'
          '- Flutter (Dart), Material Design 3, Provider\n\n'
          'Backend / Cloud\n'
          '- Firebase Authentication\n'
          '- Firebase Realtime Database\n'
          '- Firebase Cloud Messaging (FCM) (integrated; can be extended with Cloud Functions)\n\n'
          'Offline & Local\n'
          '- SQLite (sqflite) for caching\n'
          '- connectivity_plus for network detection\n\n'
          'PDF Export & Sharing\n'
          '- pdf (generate)\n'
          '- printing (share/print)\n\n'
          'Development Tools\n'
          '- Android Studio / VS Code / Cursor IDE\n'
          '- Flutter SDK + Dart SDK\n'
          '- Firebase Console\n'
          '- Git (recommended)',
          style: pStyle,
        ),
      ],
    ),
  );

  final bytes = await doc.save();

  final out = File('UniPlan_Project_Document.pdf');
  await out.writeAsBytes(bytes, flush: true);

  // Print a friendly path for the user.
  stdout.writeln('Generated: ${out.absolute.path}');
}

