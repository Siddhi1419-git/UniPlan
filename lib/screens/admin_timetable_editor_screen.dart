import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/timetable_models.dart';

class AdminTimetableEditorScreen extends StatefulWidget {
  final String semesterId;
  final String semesterName;
  final String divisionId;
  final String divisionName;

  const AdminTimetableEditorScreen({
    super.key,
    required this.semesterId,
    required this.semesterName,
    required this.divisionId,
    required this.divisionName,
  });

  @override
  State<AdminTimetableEditorScreen> createState() =>
      _AdminTimetableEditorScreenState();
}

class _AdminTimetableEditorScreenState
    extends State<AdminTimetableEditorScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<String> _days = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> _allDays = [
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
        // Ensure all days are available for selection, even if empty in DB.
        final existing = days.toSet();
        final merged = <String>[];
        for (final d in _allDays) {
          if (existing.contains(d)) {
            merged.add(d);
          } else {
            merged.add(d);
          }
        }
        _days = merged;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load timetable: $e';
        _isLoading = false;
      });
    }
  }

  static const List<String> _timeSlots = [
    '08:30-09:30', '09:30-10:30', '10:30-11:30', '11:30-12:30',
    '12:30-13:30', '13:30-14:30', '14:30-15:30', '15:30-16:30',
    '16:30-17:30', '17:30-18:30',
  ];

  Future<void> _showAddClassDialog(String day) async {
    final subjects = await _firebaseService.getSubjects();
    final teachers = await _firebaseService.getTeachers();
    final rooms = await _firebaseService.getRooms();

    if (subjects.isEmpty || teachers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subjects or teachers found. Please add them first.'),
        ),
      );
      return;
    }

    String? selectedSubjectId;
    String? selectedTeacherId;
    String? selectedRoomId;
    String? selectedTime;
    String? manualSubject;
    String? manualTeacher;
    String? manualTime;
    String? manualRoom;
    String selectedType = 'lecture';
    List<Room> displayRooms = rooms;
    List<String> displayTimeSlots = _timeSlots;

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Class - $day'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    border: OutlineInputBorder(),
                  ),
                  items: subjects.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedSubjectId = value);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Or enter subject manually',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setDialogState(() => manualSubject =
                        value.trim().isEmpty ? null : value.trim());
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type *',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'lecture', child: Text('Lecture')),
                    DropdownMenuItem(value: 'lab', child: Text('Lab')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value ?? 'lecture');
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Teacher *',
                    border: OutlineInputBorder(),
                  ),
                  items: teachers.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setDialogState(() {
                      selectedTeacherId = value;
                      manualTeacher = null;
                      selectedTime = null;
                      manualTime = null;
                      selectedRoomId = null;
                      displayTimeSlots = _timeSlots;
                      displayRooms = rooms;
                    });

                    if (value != null && rooms.isNotEmpty) {
                      final availableTimes =
                          await _firebaseService.getAvailableTimeSlotsForTeacherAndRooms(
                        day: day,
                        teacherId: value,
                        timeSlots: _timeSlots,
                        rooms: rooms,
                      );
                      setDialogState(() {
                        displayTimeSlots =
                            availableTimes.isNotEmpty ? availableTimes : [];
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Or enter teacher manually',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final trimmed = value.trim();
                    setDialogState(() {
                      manualTeacher = trimmed.isEmpty ? null : trimmed;
                      selectedTeacherId = null;
                      selectedTime = null;
                      manualTime = null;
                      selectedRoomId = null;
                      displayTimeSlots = _timeSlots;
                      displayRooms = rooms;
                    });

                    // Update availability only when we have a teacher id to compare.
                    if (trimmed.isNotEmpty && rooms.isNotEmpty) {
                      () async {
                        final availableTimes =
                            await _firebaseService.getAvailableTimeSlotsForTeacherAndRooms(
                          day: day,
                          teacherId: trimmed,
                          timeSlots: _timeSlots,
                          rooms: rooms,
                        );
                        if (!mounted) return;
                        setDialogState(() {
                          displayTimeSlots =
                              availableTimes.isNotEmpty ? availableTimes : [];
                        });
                      }();
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Time *',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedTime,
                  items: displayTimeSlots
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) async {
                    setDialogState(() {
                      selectedTime = value;
                      selectedRoomId = null;
                    });
                    if (value != null && rooms.isNotEmpty) {
                      final available = await _firebaseService.getAvailableRoomsAtSlot(day, value, rooms);
                      setDialogState(() => displayRooms = available.isNotEmpty ? available : rooms);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Or enter time manually',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 08:30-09:30',
                  ),
                  onChanged: (value) {
                    setDialogState(() => manualTime =
                        value.trim().isEmpty ? null : value.trim());
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Room *',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedRoomId,
                  items: displayRooms
                      .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedRoomId = value);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Or enter room manually',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. R5, L3',
                  ),
                  onChanged: (value) {
                    setDialogState(() => manualRoom =
                        value.trim().isEmpty ? null : value.trim());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final effectiveSubject =
                    (manualSubject ?? '').trim().isNotEmpty
                        ? manualSubject
                        : selectedSubjectId;
                final effectiveTeacher =
                    (manualTeacher ?? '').trim().isNotEmpty
                        ? manualTeacher
                        : selectedTeacherId;
                final effectiveTime = (manualTime ?? '').trim().isNotEmpty
                    ? manualTime
                    : selectedTime;
                final effectiveRoom = (manualRoom ?? '').trim().isNotEmpty
                    ? manualRoom
                    : selectedRoomId;

                if (effectiveSubject != null &&
                    effectiveTeacher != null &&
                    effectiveTime != null &&
                    effectiveRoom != null &&
                    effectiveRoom.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final effectiveSubject =
          (manualSubject ?? '').trim().isNotEmpty ? manualSubject : selectedSubjectId;
      final effectiveTeacher =
          (manualTeacher ?? '').trim().isNotEmpty ? manualTeacher : selectedTeacherId;
      final effectiveTime =
          (manualTime ?? '').trim().isNotEmpty ? manualTime : selectedTime;
      final effectiveRoom =
          (manualRoom ?? '').trim().isNotEmpty ? manualRoom : selectedRoomId;

      if (effectiveSubject == null ||
          effectiveTeacher == null ||
          effectiveTime == null ||
          effectiveRoom == null) {
        return;
      }
      try {
        final errors = await _firebaseService.validateLectureSlot(
          semesterId: widget.semesterId,
          divisionId: widget.divisionId,
          day: day,
          time: effectiveTime,
          teacherId: effectiveTeacher,
          roomId: effectiveRoom,
          subjectId: effectiveSubject,
          type: selectedType,
        );

        if (errors.isNotEmpty) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cannot Add Class'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        await _firebaseService.addClassSlot(
          semesterId: widget.semesterId,
          divisionId: widget.divisionId,
          day: day,
          time: effectiveTime,
          subjectId: effectiveSubject,
          teacherId: effectiveTeacher,
          roomId: effectiveRoom,
          type: selectedType,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class added successfully!')),
        );
        _loadDays();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadDays,
            tooltip: 'Refresh',
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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _days.map((day) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(day),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _showAddClassDialog(day),
                              tooltip: 'Add class',
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminDayDetailScreen(
                                      day: day,
                                      semesterId: widget.semesterId,
                                      divisionId: widget.divisionId,
                                      divisionName: widget.divisionName,
                                      onChanged: _loadDays,
                                      onAddClass: (d) {
                                        Navigator.pop(context);
                                        _showAddClassDialog(d);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _days.map((day) {
                  return ListTile(
                    title: Text(day),
                    onTap: () {
                      Navigator.pop(context, day);
                    },
                  );
                }).toList(),
              ),
            ),
          ).then((selectedDay) {
            if (selectedDay != null) {
              _showAddClassDialog(selectedDay);
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }
}

class AdminDayDetailScreen extends StatefulWidget {
  final String day;
  final String semesterId;
  final String divisionId;
  final String divisionName;
  final VoidCallback onChanged;
  final void Function(String day)? onAddClass;

  const AdminDayDetailScreen({
    super.key,
    required this.day,
    required this.semesterId,
    required this.divisionId,
    required this.divisionName,
    required this.onChanged,
    this.onAddClass,
  });

  @override
  State<AdminDayDetailScreen> createState() => _AdminDayDetailScreenState();
}

class _AdminDayDetailScreenState extends State<AdminDayDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Class> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
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
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteClass(Class classItem, String time) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Delete ${classItem.subject} at $time?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteClassSlot(
          semesterId: widget.semesterId,
          divisionId: widget.divisionId,
          day: widget.day,
          time: time,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully!')),
        );
        _loadClasses();
        widget.onChanged();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
      floatingActionButton: widget.onAddClass != null
          ? FloatingActionButton.extended(
              onPressed: () => widget.onAddClass!(widget.day),
              icon: const Icon(Icons.add),
              label: const Text('Add Class'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No classes scheduled for this day.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onAddClass != null) {
                            widget.onAddClass!(widget.day);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Class'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _classes.map((classItem) {
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    classItem.subject,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteClass(classItem, classItem.time),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              classItem.time,
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
                                  classItem.teacher,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.class_, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  classItem.room ?? 'Room TBA',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
