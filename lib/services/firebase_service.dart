import 'package:firebase_database/firebase_database.dart';
import '../models/timetable_models.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final CacheService _cache = CacheService();
  final ConnectivityService _connectivity = ConnectivityService();

  /// Get all semesters from `/semesters`.
  Future<List<Semester>> getSemesters() async {
    try {
      // Try to fetch from Firebase if online
      if (_connectivity.isConnected) {
        try {
          final snapshot = await _db.child('semesters').get();
          if (snapshot.exists && snapshot.value != null) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            final List<Semester> semesters = [];

            data.forEach((key, value) {
              semesters.add(Semester.fromFirebase(key.toString(), value));
            });

            semesters.sort((a, b) => a.id.compareTo(b.id));

            // Cache the data
            await _cache.cacheSemesters(
              semesters.map((s) => {'id': s.id, 'name': s.name}).toList(),
            );
            await _cache.setLastSyncTime();

            return semesters;
          }
        } catch (e) {
          print('Error fetching semesters from Firebase: $e');
          // Fall through to cache
        }
      }

      // Use cache if offline or Firebase fetch failed
      final cached = await _cache.getCachedSemesters();
      return cached.map((data) => Semester.fromFirebase(data['id'], data['name'])).toList();
    } catch (e) {
      print('Error fetching semesters: $e');
      return [];
    }
  }

  /// Get all divisions from `/divisions` (A, B, ...).
  Future<List<Division>> getDivisions() async {
    try {
      // Try to fetch from Firebase if online
      if (_connectivity.isConnected) {
        try {
          final snapshot = await _db.child('divisions').get();
          if (snapshot.exists && snapshot.value != null) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            final List<Division> divisions = [];

            data.forEach((key, value) {
              divisions.add(Division.fromFirebase(key.toString(), value));
            });

            divisions.sort((a, b) => a.id.compareTo(b.id));

            // Cache the data
            await _cache.cacheDivisions(
              divisions.map((d) => {'id': d.id, 'name': d.name}).toList(),
            );
            await _cache.setLastSyncTime();

            return divisions;
          }
        } catch (e) {
          print('Error fetching divisions from Firebase: $e');
          // Fall through to cache
        }
      }

      // Use cache if offline or Firebase fetch failed
      final cached = await _cache.getCachedDivisions();
      return cached.map((data) => Division.fromFirebase(data['id'], data['name'])).toList();
    } catch (e) {
      print('Error fetching divisions: $e');
      return [];
    }
  }

  /// Helper: fetch `/subjects` as id → name.
  Future<Map<String, String>> _getSubjectNames() async {
    try {
      // Try to fetch from Firebase if online
      if (_connectivity.isConnected) {
        try {
          final snapshot = await _db.child('subjects').get();
          if (snapshot.exists && snapshot.value != null) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            final Map<String, String> subjects = {};

            data.forEach((key, value) {
              if (value is Map && value['name'] != null) {
                subjects[key.toString()] = value['name'].toString();
              } else {
                subjects[key.toString()] = value.toString();
              }
            });

            // Cache the data
            await _cache.cacheSubjects(subjects);
            return subjects;
          }
        } catch (e) {
          print('Error fetching subjects from Firebase: $e');
          // Fall through to cache
        }
      }

      // Use cache if offline or Firebase fetch failed
      return await _cache.getCachedSubjects();
    } catch (e) {
      print('Error fetching subjects: $e');
      return {};
    }
  }

  /// Helper: fetch `/teachers` as id → name.
  Future<Map<String, String>> _getTeacherNames() async {
    try {
      // Try to fetch from Firebase if online
      if (_connectivity.isConnected) {
        try {
          final snapshot = await _db.child('teachers').get();
          if (snapshot.exists && snapshot.value != null) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            final Map<String, String> teachers = {};

            data.forEach((key, value) {
              if (value is Map && value['name'] != null) {
                teachers[key.toString()] = value['name'].toString();
              } else {
                teachers[key.toString()] = value.toString();
              }
            });

            // Cache the data
            await _cache.cacheTeachers(teachers);
            return teachers;
          }
        } catch (e) {
          print('Error fetching teachers from Firebase: $e');
          // Fall through to cache
        }
      }

      // Use cache if offline or Firebase fetch failed
      return await _cache.getCachedTeachers();
    } catch (e) {
      print('Error fetching teachers: $e');
      return {};
    }
  }

  /// Get timetable for a specific semester + division.
  ///
  /// Data is read from: `/timetables/{semesterId}/{divisionId}`.
  /// Under that node, keys are day names (Monday, Tuesday, ...) and
  /// under each day the keys are time ranges (e.g. "08:30-09:30").
  Future<Map<String, List<Class>>> getTimetableForSemesterAndDivision(
    String semesterId,
    String divisionId,
  ) async {
    try {
      final subjects = await _getSubjectNames();
      final teachers = await _getTeacherNames();

      // Try to fetch from Firebase if online
      if (_connectivity.isConnected) {
        try {
          final snapshot =
              await _db.child('timetables').child(semesterId).child(divisionId).get();

          if (snapshot.exists && snapshot.value != null) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            final Map<String, List<Class>> timetable = {};

            // data: { "Monday": { "08:30-09:30": {...}, ... }, "Tuesday": { ... } }
            data.forEach((dayKey, dayData) {
              if (dayData is! Map) return;

              final String day = dayKey.toString();
              final List<Class> classes = [];

              dayData.forEach((timeKey, slotData) {
                if (slotData is! Map) return;

                final time = timeKey.toString();
                final subjectId = slotData['subject']?.toString() ?? '';
                final teacherId = slotData['teacher']?.toString() ?? '';
                final room = slotData['room']?.toString();
                final type = slotData['type']?.toString() ?? 'lecture';

                final subjectName = subjects[subjectId] ?? subjectId;
                final teacherName = teachers[teacherId] ?? teacherId;

                classes.add(
                  Class(
                    time: time,
                    subject: subjectName,
                    teacher: teacherName,
                    room: room,
                    type: type,
                  ),
                );
              });

              // Sort classes by time string so they appear in order.
              classes.sort((a, b) => a.time.compareTo(b.time));

              if (classes.isNotEmpty) {
                timetable[day] = classes;
                
                // Cache each day's data
                _cache.cacheTimetable(
                  semesterId: semesterId,
                  divisionId: divisionId,
                  day: day,
                  data: {
                    'classes': classes.map((c) => {
                      'time': c.time,
                      'subject': c.subject,
                      'teacher': c.teacher,
                      'room': c.room,
                      'type': c.type,
                    }).toList(),
                  },
                );
              }
            });

            await _cache.setLastSyncTime();
            return timetable;
          }
        } catch (e) {
          print('Error fetching timetable from Firebase: $e');
          // Fall through to cache
        }
      }

      // Use cache if offline or Firebase fetch failed
      final Map<String, List<Class>> timetable = {};
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      for (final day in days) {
        final cached = await _cache.getCachedTimetable(
          semesterId: semesterId,
          divisionId: divisionId,
          day: day,
        );
        
        if (cached != null && cached['classes'] != null) {
          final classes = (cached['classes'] as List).map((c) => Class(
            time: c['time'] ?? '',
            subject: c['subject'] ?? '',
            teacher: c['teacher'] ?? '',
            room: c['room'],
            type: c['type'] ?? 'lecture',
          )).toList();
          
          if (classes.isNotEmpty) {
            timetable[day] = classes;
          }
        }
      }

      return timetable;
    } catch (e) {
      print(
        'Error fetching timetable for semester $semesterId '
        'division $divisionId: $e',
      );
      return {};
    }
  }

  /// Get all days that have classes for a given semester + division.
  Future<List<String>> getDaysForSemesterAndDivision(
    String semesterId,
    String divisionId,
  ) async {
    try {
      final timetable =
          await getTimetableForSemesterAndDivision(semesterId, divisionId);
      final days = timetable.keys.toList();

      const order = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      days.sort(
        (a, b) => order.indexOf(a).compareTo(order.indexOf(b)),
      );

      return days;
    } catch (e) {
      // ignore: avoid_print
      print(
        'Error fetching days for semester $semesterId '
        'division $divisionId: $e',
      );
      return [];
    }
  }

  /// Get all classes scheduled for a specific day.
  Future<List<Class>> getClassesForDay(
    String semesterId,
    String divisionId,
    String day,
  ) async {
    try {
      final timetable =
          await getTimetableForSemesterAndDivision(semesterId, divisionId);
      return timetable[day] ?? [];
    } catch (e) {
      // ignore: avoid_print
      print(
        'Error fetching classes for semester $semesterId '
        'division $divisionId, day $day: $e',
      );
      return [];
    }
  }

  // ========== ADMIN METHODS ==========

  /// Get all rooms from `/rooms`.
  Future<List<Room>> getRooms() async {
    try {
      final snapshot = await _db.child('rooms').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final List<Room> rooms = [];

      data.forEach((key, value) {
        rooms.add(Room.fromFirebase(key.toString(), value));
      });

      rooms.sort((a, b) => a.name.compareTo(b.name));
      return rooms;
    } catch (e) {
      print('Error fetching rooms: $e');
      return [];
    }
  }

  /// Get all subjects for admin dropdown.
  Future<List<MapEntry<String, String>>> getSubjects() async {
    try {
      final subjects = await _getSubjectNames();
      return subjects.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  /// Get all teachers for admin dropdown.
  Future<List<MapEntry<String, String>>> getTeachers() async {
    try {
      final teachers = await _getTeacherNames();
      return teachers.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }

  /// Add a new class slot to timetable.
  Future<void> addClassSlot({
    required String semesterId,
    required String divisionId,
    required String day,
    required String time,
    required String subjectId,
    required String teacherId,
    required String roomId,
    String type = 'lecture',
  }) async {
    try {
      await _db
          .child('timetables')
          .child(semesterId)
          .child(divisionId)
          .child(day)
          .child(time)
          .set({
        'subject': subjectId,
        'teacher': teacherId,
        'room': roomId,
        'type': type,
      });
    } catch (e) {
      print('Error adding class slot: $e');
      rethrow;
    }
  }

  /// Update an existing class slot.
  Future<void> updateClassSlot({
    required String semesterId,
    required String divisionId,
    required String day,
    required String oldTime,
    required String newTime,
    required String subjectId,
    required String teacherId,
    required String roomId,
    String type = 'lecture',
  }) async {
    try {
      final path = _db
          .child('timetables')
          .child(semesterId)
          .child(divisionId)
          .child(day);

      // Delete old slot
      await path.child(oldTime).remove();

      // Add new slot
      await path.child(newTime).set({
        'subject': subjectId,
        'teacher': teacherId,
        'room': roomId,
        'type': type,
      });
    } catch (e) {
      print('Error updating class slot: $e');
      rethrow;
    }
  }

  // ========== VALIDATION METHODS ==========

  /// Get all timetable slots at a given day+time across ALL semesters/divisions.
  Future<List<RawSlot>> _getAllSlotsAtDayTime(String day, String time) async {
    try {
      final snapshot = await _db.child('timetables').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final List<RawSlot> slots = [];

      data.forEach((semId, semData) {
        if (semData is! Map) return;
        semData.forEach((divId, divData) {
          if (divData is! Map) return;
          final dayData = divData[day];
          if (dayData is! Map) return;
          final slotData = dayData[time];
          if (slotData is! Map) return;

          slots.add(RawSlot(
            day: day,
            time: time,
            subjectId: slotData['subject']?.toString() ?? '',
            teacherId: slotData['teacher']?.toString() ?? '',
            roomId: slotData['room']?.toString() ?? '',
            type: slotData['type']?.toString() ?? 'lecture',
            semesterId: semId.toString(),
            divisionId: divId.toString(),
          ));
        });
      });

      return slots;
    } catch (e) {
      print('Error getting slots at day/time: $e');
      return [];
    }
  }

  /// Fetch all slots for a given day across ALL semesters/divisions.
  /// Returns map: { timeRange: [RawSlot, ...] }
  Future<Map<String, List<RawSlot>>> _getSlotsForDay(String day) async {
    try {
      final snapshot = await _db.child('timetables').get();
      if (!snapshot.exists || snapshot.value == null) return {};

      final data = snapshot.value as Map<dynamic, dynamic>;
      final Map<String, List<RawSlot>> slotsByTime = {};

      for (final semIdEntry in data.entries) {
        final semData = semIdEntry.value;
        if (semData is! Map) continue;

        final semId = semIdEntry.key.toString();

        for (final divIdEntry in semData.entries) {
          final divData = divIdEntry.value;
          if (divData is! Map) continue;

          final divId = divIdEntry.key.toString();

          final dayData = divData[day];
          if (dayData is! Map) continue;

          dayData.forEach((timeKey, slotData) {
            if (slotData is! Map) return;

            final time = timeKey.toString();
            slotsByTime.putIfAbsent(time, () => []);
            slotsByTime[time]!.add(
              RawSlot(
                day: day,
                time: time,
                subjectId: slotData['subject']?.toString() ?? '',
                teacherId: slotData['teacher']?.toString() ?? '',
                roomId: slotData['room']?.toString() ?? '',
                type: slotData['type']?.toString() ?? 'lecture',
                semesterId: semId,
                divisionId: divId,
              ),
            );
          });
        }
      }

      return slotsByTime;
    } catch (e) {
      print('Error getting slots for day $day: $e');
      return {};
    }
  }

  /// Returns time slots where:
  /// - the given teacher is free (no lecture/lab at that time)
  /// - AND at least one room is free at that time
  ///
  /// This is used to show "free available time slots" in the admin dialog.
  Future<List<String>> getAvailableTimeSlotsForTeacherAndRooms({
    required String day,
    required String teacherId,
    required List<String> timeSlots,
    required List<Room> rooms,
  }) async {
    if (teacherId.trim().isEmpty) return [];
    if (rooms.isEmpty) return [];

    final slotsByTime = await _getSlotsForDay(day);
    final List<String> availableTimes = [];

    for (final time in timeSlots) {
      final slotsAtTime = slotsByTime[time] ?? [];

      final teacherBusy = slotsAtTime.any((s) => s.teacherId == teacherId);
      if (teacherBusy) continue;

      final usedRoomIds = slotsAtTime.map((s) => s.roomId).toSet();
      final availableRooms =
          rooms.where((r) => !usedRoomIds.contains(r.id)).toList();

      if (availableRooms.isNotEmpty) {
        availableTimes.add(time);
      }
    }

    return availableTimes;
  }

  /// Get all raw slots for a semester+division (for subject limit validation).
  Future<List<RawSlot>> _getRawTimetableForSemesterDivision(
    String semesterId,
    String divisionId,
  ) async {
    try {
      final snapshot = _db
          .child('timetables')
          .child(semesterId)
          .child(divisionId)
          .get();

      final result = await snapshot;
      if (!result.exists || result.value == null) return [];

      final data = result.value as Map<dynamic, dynamic>;
      final List<RawSlot> slots = [];

      data.forEach((dayKey, dayData) {
        if (dayData is! Map) return;
        final day = dayKey.toString();
        dayData.forEach((timeKey, slotData) {
          if (slotData is! Map) return;
          slots.add(RawSlot(
            day: day,
            time: timeKey.toString(),
            subjectId: slotData['subject']?.toString() ?? '',
            teacherId: slotData['teacher']?.toString() ?? '',
            roomId: slotData['room']?.toString() ?? '',
            type: slotData['type']?.toString() ?? 'lecture',
            semesterId: semesterId,
            divisionId: divisionId,
          ));
        });
      });

      return slots;
    } catch (e) {
      print('Error getting raw timetable: $e');
      return [];
    }
  }

  /// Validate adding/updating a class slot. Returns list of error messages.
  Future<List<String>> validateLectureSlot({
    required String semesterId,
    required String divisionId,
    required String day,
    required String time,
    required String teacherId,
    required String roomId,
    required String subjectId,
    required String type,
    String? excludeExistingTime, // For updates: exclude the slot being edited
  }) async {
    final errors = <String>[];

    // 1. Get all slots at this day+time
    var slotsAtTime = await _getAllSlotsAtDayTime(day, time);

    // Exclude the slot we're editing (for update case)
    if (excludeExistingTime != null) {
      slotsAtTime = slotsAtTime.where((s) =>
        !(s.semesterId == semesterId && s.divisionId == divisionId && s.time == excludeExistingTime)
      ).toList();
    }

    // 2. Teacher conflict: same teacher at same time
    final teacherConflict = slotsAtTime.any((s) => s.teacherId == teacherId);
    if (teacherConflict) {
      errors.add('This teacher already has another lecture at $time on $day.');
    }

    // 3. Room conflict: same room at same time
    final roomConflict = slotsAtTime.any((s) => s.roomId == roomId);
    if (roomConflict) {
      errors.add('This room is already assigned at $time on $day.');
    }

    // 4. Class conflict: same semester+division already has a class at this time
    final ourSlots = await _getRawTimetableForSemesterDivision(semesterId, divisionId);
    var ourSlotAtTime = ourSlots.where((s) => s.day == day && s.time == time).toList();
    if (excludeExistingTime != null) {
      ourSlotAtTime = ourSlotAtTime.where((s) => s.time != excludeExistingTime).toList();
    }
    if (ourSlotAtTime.isNotEmpty) {
      errors.add('This class already has a lecture scheduled at $time on $day.');
    }

    // 5. Subject limit: max 4 lectures + 1 lab per week
    var allSlots = await _getRawTimetableForSemesterDivision(semesterId, divisionId);
    if (excludeExistingTime != null) {
      allSlots = allSlots.where((s) => !(s.day == day && s.time == excludeExistingTime)).toList();
    }

    final subjectSlots = allSlots.where((s) => s.subjectId == subjectId).toList();
    final lectureCount = subjectSlots.where((s) => s.type == 'lecture').length;
    final labCount = subjectSlots.where((s) => s.type == 'lab').length;

    // Add the new slot to the count
    final newIsLecture = type == 'lecture';
    if (newIsLecture) {
      if (lectureCount >= 4) {
        errors.add('This subject already has 4 lectures per week. Maximum allowed is 4.');
      }
    } else {
      if (labCount >= 1) {
        errors.add('This subject already has 1 lab per week. Maximum allowed is 1.');
      }
    }

    return errors;
  }

  /// Get rooms available at a given day+time (optional feature).
  Future<List<Room>> getAvailableRoomsAtSlot(
    String day,
    String time,
    List<Room> allRooms,
  ) async {
    final slotsAtTime = await _getAllSlotsAtDayTime(day, time);
    final usedRoomIds = slotsAtTime.map((s) => s.roomId).toSet();
    return allRooms.where((r) => !usedRoomIds.contains(r.id)).toList();
  }

  /// Get subject limit warnings for student dashboard.
  /// Returns list of {subjectName, lectureCount, labCount, hasWarning}.
  Future<List<Map<String, dynamic>>> getSubjectLimitWarnings(
    String semesterId,
    String divisionId,
  ) async {
    final slots = await _getRawTimetableForSemesterDivision(semesterId, divisionId);
    final subjects = await _getSubjectNames();

    // Group by subject
    final Map<String, List<RawSlot>> bySubject = {};
    for (final slot in slots) {
      if (slot.subjectId.isEmpty) continue;
      bySubject.putIfAbsent(slot.subjectId, () => []).add(slot);
    }

    final List<Map<String, dynamic>> warnings = [];

    for (final entry in bySubject.entries) {
      final subjectId = entry.key;
      final subjectSlots = entry.value;
      final lectureCount = subjectSlots.where((s) => s.type == 'lecture').length;
      final labCount = subjectSlots.where((s) => s.type == 'lab').length;

      const maxLectures = 4;
      const maxLabs = 1;

      final subjectName = subjects[subjectId] ?? subjectId;
      final List<String> issues = [];

      if (lectureCount < maxLectures) {
        issues.add('$lectureCount/$maxLectures lectures (needs ${maxLectures - lectureCount} more)');
      }
      if (labCount < maxLabs) {
        issues.add('$labCount/$maxLabs lab (missing)');
      }
      if (lectureCount > maxLectures) {
        issues.add('$lectureCount/$maxLectures lectures (exceeds limit)');
      }

      if (issues.isNotEmpty) {
        warnings.add({
          'subjectName': subjectName,
          'subjectId': subjectId,
          'lectureCount': lectureCount,
          'labCount': labCount,
          'message': '${subjectName}: ${issues.join(', ')}',
        });
      }
    }

    return warnings;
  }

  bool _semesterIdsMatch(String target, String student) {
    if (target.isEmpty || student.isEmpty) return target == student;
    final t = target.trim().toLowerCase();
    final s = student.trim().toLowerCase();
    if (t == s) return true;
    if (t == 'sem$s' || s == 'sem$t') return true;
    return false;
  }

  /// Get announcements for a student (matches semester/division or "all").
  Future<List<Map<String, dynamic>>> getAnnouncements(
    String semesterId,
    String divisionId,
  ) async {
    try {
      final snapshot = await _db.child('announcements').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> result = [];

      data.forEach((key, value) {
        if (value is! Map) return;
        final targetSem = (value['semesterId']?.toString() ?? '').trim();
        final targetDiv = (value['divisionId']?.toString() ?? '').trim();

        bool matches = false;
        if (targetSem.isEmpty) {
          matches = true; // Sent to all
        } else {
          final semMatch = _semesterIdsMatch(targetSem, semesterId);
          if (semMatch) {
            matches = targetDiv.isEmpty || targetDiv == divisionId;
          }
        }

        if (matches) {
          result.add({
            'title': value['title']?.toString() ?? '',
            'body': value['body']?.toString() ?? '',
            'timestamp': value['timestamp']?.toString() ?? '',
          });
        }
      });

      result.sort((a, b) {
        final ta = a['timestamp'] as String;
        final tb = b['timestamp'] as String;
        return tb.compareTo(ta); // Newest first
      });

      return result.take(10).toList(); // Latest 10
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  /// Get announcements with per-user metadata (pinned/deleted) for notifications screen.
  Future<List<Map<String, dynamic>>> getAnnouncementsForUser(
    String uid,
    String semesterId,
    String divisionId,
  ) async {
    try {
      final annsSnap = await _db.child('announcements').get();
      if (!annsSnap.exists || annsSnap.value == null) return [];

      final metaSnap = await _db.child('userAnnouncements').child(uid).get();
      final metaData =
          metaSnap.exists && metaSnap.value is Map ? metaSnap.value as Map : {};

      final data = annsSnap.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> result = [];

      data.forEach((key, value) {
        if (value is! Map) return;
        final id = key.toString();

        final targetSem = (value['semesterId']?.toString() ?? '').trim();
        final targetDiv = (value['divisionId']?.toString() ?? '').trim();

        bool matches = false;
        if (targetSem.isEmpty) {
          matches = true;
        } else {
          final semMatch = _semesterIdsMatch(targetSem, semesterId);
          if (semMatch) {
            matches = targetDiv.isEmpty || targetDiv == divisionId;
          }
        }

        if (!matches) return;

        final meta = metaData[id] is Map ? metaData[id] as Map : {};
        if (meta['deleted'] == true) return;

        result.add({
          'id': id,
          'title': value['title']?.toString() ?? '',
          'body': value['body']?.toString() ?? '',
          'timestamp': value['timestamp']?.toString() ?? '',
          'pinned': meta['pinned'] == true,
        });
      });

      result.sort((a, b) {
        final ap = a['pinned'] == true;
        final bp = b['pinned'] == true;
        if (ap != bp) {
          return bp ? 1 : -1; // pinned first
        }
        final ta = a['timestamp'] as String? ?? '';
        final tb = b['timestamp'] as String? ?? '';
        return tb.compareTo(ta); // newest first
      });

      return result;
    } catch (e) {
      print('Error fetching announcements for user: $e');
      return [];
    }
  }

  Future<void> setAnnouncementPinned(
    String uid,
    String announcementId,
    bool pinned,
  ) async {
    try {
      await _db
          .child('userAnnouncements')
          .child(uid)
          .child(announcementId)
          .update({'pinned': pinned});
    } catch (e) {
      print('Error setting pinned: $e');
      rethrow;
    }
  }

  Future<void> setAnnouncementDeleted(
    String uid,
    String announcementId,
    bool deleted,
  ) async {
    try {
      await _db
          .child('userAnnouncements')
          .child(uid)
          .child(announcementId)
          .update({'deleted': deleted});
    } catch (e) {
      print('Error setting deleted: $e');
      rethrow;
    }
  }

  /// Delete a class slot.
  Future<void> deleteClassSlot({
    required String semesterId,
    required String divisionId,
    required String day,
    required String time,
  }) async {
    try {
      await _db
          .child('timetables')
          .child(semesterId)
          .child(divisionId)
          .child(day)
          .child(time)
          .remove();
    } catch (e) {
      print('Error deleting class slot: $e');
      rethrow;
    }
  }
}
