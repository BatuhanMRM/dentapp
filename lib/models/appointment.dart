enum AppointmentStatus { all, pending, confirmed, completed, cancelled }

class Appointment {
  final String id;
  final String userId;
  final String patientName;
  final String patientPhone;
  final String? doctorId; // Hangi doktora randevu
  final String? doctorName; // Doktor adı (cache için)
  final DateTime appointmentDate;
  final String timeSlot;
  final String treatmentType;
  final String notes;
  final AppointmentStatus status;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    this.doctorId,
    this.doctorName,
    required this.appointmentDate,
    required this.timeSlot,
    required this.treatmentType,
    this.notes = '',
    this.status = AppointmentStatus.pending,
    required this.createdAt,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientPhone: map['patientPhone'] ?? '',
      doctorId: map['doctorId'],
      doctorName: map['doctorName'],
      appointmentDate: DateTime.parse(map['appointmentDate']),
      timeSlot: map['timeSlot'] ?? '',
      treatmentType: map['treatmentType'] ?? '',
      notes: map['notes'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == 'AppointmentStatus.${map['status']}',
        orElse: () => AppointmentStatus.pending,
      ),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'treatmentType': treatmentType,
      'notes': notes,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? userId,
    String? patientName,
    String? patientPhone,
    String? doctorId,
    String? doctorName,
    DateTime? appointmentDate,
    String? timeSlot,
    String? treatmentType,
    String? notes,
    AppointmentStatus? status,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      treatmentType: treatmentType ?? this.treatmentType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
