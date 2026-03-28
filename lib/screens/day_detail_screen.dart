import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/timetable_models.dart';

class DayDetailScreen extends StatefulWidget {
  final String day;
  final String semesterId;
  final String divisionId;
  final String divisionName;

  const DayDetailScreen({
    super.key,
    required this.day,
    required this.semesterId,
    required this.divisionId,
    required this.divisionName,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Class> _classes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classes = await _firebaseService.getClassesForDay(
        widget.semesterId,
        widget.divisionId,
        widget.day,
      );
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load classes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${widget.day} • ${widget.divisionName}'),
        centerTitle: true,
        elevation: 0,
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
                        onPressed: _loadClasses,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _classes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No classes scheduled for this day.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadClasses,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadClasses,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _classes.map((classItem) {
                          return TimetableCard(
                            time: classItem.time,
                            subject: classItem.subject,
                            teacher: classItem.teacher,
                            room: classItem.room,
                          );
                        }).toList(),
                      ),
                    ),
    );
  }
}

class TimetableCard extends StatelessWidget {
  final String time;
  final String subject;
  final String teacher;
  final String? room;

  const TimetableCard({
    super.key,
    required this.time,
    required this.subject,
    required this.teacher,
    this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 6),
                Text(
                  teacher,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.class_, size: 16),
                const SizedBox(width: 6),
                Text(
                  room ?? 'Room TBA',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
