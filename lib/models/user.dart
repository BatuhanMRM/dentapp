enum UserType { patient, doctor }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserType userType;
  final String? specialty; // Sadece doktorlar için
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.specialty,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${map['userType'] ?? 'patient'}',
        orElse: () => UserType.patient,
      ),
      specialty: map['specialty'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType.toString().split('.').last,
      'specialty': specialty,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isDoctor => userType == UserType.doctor;
  bool get isPatient => userType == UserType.patient;
}
