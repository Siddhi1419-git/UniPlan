import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/timetable_models.dart';
import 'division_selection_screen.dart';

class SemesterSelectionScreen extends StatefulWidget {
  const SemesterSelectionScreen({super.key});

  @override
  State<SemesterSelectionScreen> createState() =>
      _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends State<SemesterSelectionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Semester> _semesters = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final semesters = await _firebaseService.getSemesters();
      setState(() {
        _semesters = semesters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load semesters: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Semester'),
        centerTitle: true,
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
                        onPressed: _loadSemesters,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _semesters.isEmpty
                  ? const Center(
                      child: Text(
                        'No semesters found.\n\nAsk your partner to add data in Firebase Console under "semesters" path.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSemesters,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _semesters.length,
                        itemBuilder: (context, index) {
                          final semester = _semesters[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(semester.name),
                              subtitle: Text('ID: ${semester.id}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DivisionSelectionScreen(
                                      semesterId: semester.id,
                                      semesterName: semester.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
