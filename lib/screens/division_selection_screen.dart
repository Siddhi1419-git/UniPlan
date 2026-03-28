import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/timetable_models.dart';
import 'timetable_screen.dart';

class DivisionSelectionScreen extends StatefulWidget {
  final String semesterId;
  final String semesterName;

  const DivisionSelectionScreen({
    super.key,
    required this.semesterId,
    required this.semesterName,
  });

  @override
  State<DivisionSelectionScreen> createState() =>
      _DivisionSelectionScreenState();
}

class _DivisionSelectionScreenState extends State<DivisionSelectionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Division> _divisions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final divisions = await _firebaseService.getDivisions();
      setState(() {
        _divisions = divisions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load divisions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Division • ${widget.semesterName}'),
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
                        onPressed: _loadDivisions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _divisions.isEmpty
                  ? const Center(
                      child: Text(
                        'No divisions found.\n\nAsk your partner to add data in Firebase Console under "divisions".',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDivisions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _divisions.length,
                        itemBuilder: (context, index) {
                          final division = _divisions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(division.name),
                              subtitle: Text('ID: ${division.id}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TimetableScreen(
                                      semesterId: widget.semesterId,
                                      semesterName: widget.semesterName,
                                      divisionId: division.id,
                                      divisionName: division.name,
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

