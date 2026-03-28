import 'package:flutter/material.dart';
import '../navigation/bottom_nav.dart';

/// Entry point for students after login.
///
/// For now this simply shows the existing BottomNav. Later we can
/// use [semesterId] and [divisionId] to auto-filter the timetable.
class StudentHomeScreen extends StatelessWidget {
  final String? semesterId;
  final String? divisionId;

  const StudentHomeScreen({
    super.key,
    this.semesterId,
    this.divisionId,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNav(
      semesterId: semesterId,
      divisionId: divisionId,
    );
  }
}

