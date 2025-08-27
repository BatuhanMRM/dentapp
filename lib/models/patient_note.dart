class PatientNote {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String title;
  final String content;
  final PatientNoteType type;
  final bool isCompleted;
  final DateTime dueDate;
  final DateTime createdAt;

  PatientNote({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.title,
    required this.content,
    required this.type,
    this.isCompleted = false,
    required this.dueDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'isCompleted': isCompleted,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatientNote.fromMap(Map<String, dynamic> map) {
    return PatientNote(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: PatientNoteType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => PatientNoteType.general,
      ),
      isCompleted: map['isCompleted'] ?? false,
      dueDate: DateTime.parse(map['dueDate']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  PatientNote copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? doctorName,
    String? title,
    String? content,
    PatientNoteType? type,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return PatientNote(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum PatientNoteType { general, reminder, treatment, prescription, followUp }
