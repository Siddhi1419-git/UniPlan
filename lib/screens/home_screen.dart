import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/timetable_models.dart';
import 'day_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? semesterId;
  final String? divisionId;

  const HomeScreen({
    super.key,
    this.semesterId,
    this.divisionId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Class> _todayClasses = [];
  bool _isLoading = true;
  String? _error;
  String _todayDay = '';

  @override
  void initState() {
    super.initState();
    _loadTodayClasses();
  }

  Future<void> _loadTodayClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ];
      _todayDay = days[now.weekday - 1];

      List<Class> classes = [];
      String? loadError;
      if (widget.semesterId != null && widget.divisionId != null) {
        classes = await _firebaseService.getClassesForDay(
          widget.semesterId!,
          widget.divisionId!,
          _todayDay,
        );
      } else {
        loadError =
            'Semester and division not set. Please select from Timetable tab.';
      }

      setState(() {
        _todayClasses = classes;
        _error = loadError;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniPlan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayClasses,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadTodayClasses,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_todayClasses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No classes scheduled for today ($_todayDay).',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildTodayClassesContent(),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildTodayClassesContent() {
    return [
      Row(
        children: [
          const Text(
            'Today',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(_todayDay, style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.blue.shade50,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '${_todayClasses.length} class${_todayClasses.length > 1 ? 'es' : ''} scheduled',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      ),
      const SizedBox(height: 16),
      ..._todayClasses.map((classItem) => _buildClassCard(classItem)),
    ];
  }

  Widget _buildClassCard(Class classItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailScreen(
                day: _todayDay,
                semesterId: widget.semesterId!,
                divisionId: widget.divisionId!,
                divisionName: widget.divisionId!,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classItem.subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          classItem.time,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classItem.teacher,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.class_, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          classItem.room ?? 'TBA',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
