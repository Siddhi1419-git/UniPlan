// Data models to structure Firebase data

/// Represents a semester, e.g. `sem6` → "Semester 6".
class Semester {
  final String id;
  final String name;

  Semester({required this.id, required this.name});

  // Convert from Firebase Map under /semesters
  factory Semester.fromFirebase(String id, dynamic data) {
    if (data is Map && data['name'] != null) {
      return Semester(id: id, name: data['name'].toString());
    }
    return Semester(id: id, name: data.toString());
  }
}

/// Represents a room, e.g. `R5` → "R5 - Room 5" or "R101 (Classroom)".
class Room {
  final String id;
  final String name;  // Display name: "R101 - Classroom", "R5", etc.

  Room({required this.id, required this.name});

  factory Room.fromFirebase(String id, dynamic data) {
    if (data is! Map) {
      return Room(id: id, name: id);
    }
    final nameVal = data['name']?.toString();
    final typeVal = data['type']?.toString();
    if (nameVal != null && nameVal.isNotEmpty) {
      return Room(id: id, name: nameVal);
    }
    if (typeVal != null && typeVal.isNotEmpty) {
      return Room(id: id, name: '$id ($typeVal)');
    }
    return Room(id: id, name: id);
  }
}

/// Represents a division, e.g. `A` → "Division A".
class Division {
  final String id;
  final String name;

  Division({required this.id, required this.name});

  // Convert from Firebase Map under /divisions
  factory Division.fromFirebase(String id, dynamic data) {
    if (data is Map && data['name'] != null) {
      return Division(id: id, name: data['name'].toString());
    }
    return Division(id: id, name: data.toString());
  }
}

/// One class/lecture entry in the timetable.
class Class {
  final String time; // e.g. "08:30-09:30"
  final String subject; // e.g. "ML"
  final String teacher; // e.g. "BNB"
  final String? room; // e.g. "R5"
  final String type; // "lecture" or "lab"

  Class({
    required this.time,
    required this.subject,
    required this.teacher,
    this.room,
    this.type = 'lecture',
  });
}

/// Raw slot data with IDs for validation (used internally).
class RawSlot {
  final String day;
  final String time;
  final String subjectId;
  final String teacherId;
  final String roomId;
  final String type; // "lecture" or "lab"
  final String semesterId;
  final String divisionId;

  RawSlot({
    required this.day,
    required this.time,
    required this.subjectId,
    required this.teacherId,
    required this.roomId,
    this.type = 'lecture',
    this.semesterId = '',
    this.divisionId = '',
  });
}

/// Convenience wrapper if you ever need a whole day's schedule.
class DaySchedule {
  final String day;
  final List<Class> classes;

  DaySchedule({required this.day, required this.classes});
}
