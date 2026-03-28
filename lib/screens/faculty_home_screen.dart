import 'package:flutter/material.dart';

/// Very simple placeholder for faculty home.
///
/// We can later extend this to show only the classes for the
/// logged-in faculty member, using their [teacherId].
class FacultyHomeScreen extends StatelessWidget {
  final String teacherId;

  const FacultyHomeScreen({
    super.key,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Home'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Logged in as faculty (teacherId: $teacherId).\n\n'
          'Timetable view for this teacher can be added here.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

