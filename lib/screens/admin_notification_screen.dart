import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/firebase_service.dart';
import '../models/timetable_models.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  List<Semester> _semesters = [];
  List<Division> _divisions = [];
  String? _selectedSemesterId;
  String? _selectedDivisionId;
  bool _isLoading = false;
  bool _sendToAll = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final semesters = await _firebaseService.getSemesters();
      final divisions = await _firebaseService.getDivisions();
      setState(() {
        _semesters = semesters;
        _divisions = divisions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.sendNotificationToUsers(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        semesterId: _sendToAll ? null : _selectedSemesterId,
        divisionId: _sendToAll ? null : _selectedDivisionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _selectedSemesterId = null;
          _selectedDivisionId = null;
          _sendToAll = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active,
                        size: 40, color: Colors.blue.shade700),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send Announcements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Notify students about updates',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter notification title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Message *',
                hintText: 'Enter notification message',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Card(
              child: SwitchListTile(
                title: const Text('Send to All Students'),
                subtitle: const Text('Uncheck to send to specific group'),
                value: _sendToAll,
                onChanged: (value) {
                  setState(() {
                    _sendToAll = value;
                    if (value) {
                      _selectedSemesterId = null;
                      _selectedDivisionId = null;
                    }
                  });
                },
              ),
            ),
            if (!_sendToAll) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSemesterId,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                items: _semesters.map((semester) {
                  return DropdownMenuItem(
                    value: semester.id,
                    child: Text(semester.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSemesterId = value;
                    _selectedDivisionId = null; // Reset division when semester changes
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedSemesterId != null)
                DropdownButtonFormField<String>(
                  value: _selectedDivisionId,
                  decoration: const InputDecoration(
                    labelText: 'Division',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  items: _divisions.map((division) {
                    return DropdownMenuItem(
                      value: division.id,
                      child: Text(division.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDivisionId = value;
                    });
                  },
                ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendNotification,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Sending...' : 'Send Notification'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
