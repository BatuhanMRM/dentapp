class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final String treatment;
  final String diagnosis;
  final String prescription;
  final String notes;
  final List<String> attachments; // Dosya yolları için
  final DateTime createdAt;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.treatment,
    required this.diagnosis,
    required this.prescription,
    required this.notes,
    required this.attachments,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': date.toIso8601String(),
      'treatment': treatment,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      date: DateTime.parse(map['date']),
      treatment: map['treatment'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      prescription: map['prescription'] ?? '',
      notes: map['notes'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  MedicalRecord copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? doctorName,
    DateTime? date,
    String? treatment,
    String? diagnosis,
    String? prescription,
    String? notes,
    List<String>? attachments,
    DateTime? createdAt,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      date: date ?? this.date,
      treatment: treatment ?? this.treatment,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
