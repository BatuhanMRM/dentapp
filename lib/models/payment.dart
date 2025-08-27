class Payment {
  final String id;
  final String userId;
  final String appointmentId;
  final String doctorId;
  final double amount;
  final String currency;
  final PaymentType type;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? description;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final String? refundReason;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.userId,
    required this.appointmentId,
    required this.doctorId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.method,
    this.description,
    this.transactionId,
    required this.createdAt,
    this.paidAt,
    this.refundedAt,
    this.refundReason,
    this.metadata,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      userId: json['userId'],
      appointmentId: json['appointmentId'],
      doctorId: json['doctorId'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      type: PaymentType.values.firstWhere((e) => e.name == json['type']),
      status: PaymentStatus.values.firstWhere((e) => e.name == json['status']),
      method: PaymentMethod.values.firstWhere((e) => e.name == json['method']),
      description: json['description'],
      transactionId: json['transactionId'],
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'])
          : null,
      refundReason: json['refundReason'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'status': status.name,
      'method': method.name,
      'description': description,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
      'refundReason': refundReason,
      'metadata': metadata,
    };
  }

  Payment copyWith({
    String? id,
    String? userId,
    String? appointmentId,
    String? doctorId,
    double? amount,
    String? currency,
    PaymentType? type,
    PaymentStatus? status,
    PaymentMethod? method,
    String? description,
    String? transactionId,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? refundedAt,
    String? refundReason,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      method: method ?? this.method,
      description: description ?? this.description,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      refundedAt: refundedAt ?? this.refundedAt,
      refundReason: refundReason ?? this.refundReason,
      metadata: metadata ?? this.metadata,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Bekliyor';
      case PaymentStatus.processing:
        return 'İşleniyor';
      case PaymentStatus.completed:
        return 'Tamamlandı';
      case PaymentStatus.failed:
        return 'Başarısız';
      case PaymentStatus.cancelled:
        return 'İptal Edildi';
      case PaymentStatus.refunded:
        return 'İade Edildi';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case PaymentType.appointmentDeposit:
        return 'Randevu Kaparası';
      case PaymentType.treatmentPayment:
        return 'Tedavi Ödemesi';
      case PaymentType.fullPayment:
        return 'Tam Ödeme';
    }
  }

  String get methodDisplayName {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Kredi Kartı';
      case PaymentMethod.debitCard:
        return 'Banka Kartı';
      case PaymentMethod.bankTransfer:
        return 'Havale/EFT';
      case PaymentMethod.cash:
        return 'Nakit';
    }
  }
}

enum PaymentType {
  appointmentDeposit, // Randevu kaparası
  treatmentPayment, // Tedavi ödemesi
  fullPayment, // Tam ödeme
}

enum PaymentStatus {
  pending, // Bekliyor
  processing, // İşleniyor
  completed, // Tamamlandı
  failed, // Başarısız
  cancelled, // İptal edildi
  refunded, // İade edildi
}

enum PaymentMethod {
  creditCard, // Kredi kartı
  debitCard, // Banka kartı
  bankTransfer, // Havale/EFT
  cash, // Nakit
}

class PaymentSettings {
  final double appointmentDepositPercentage;
  final double minimumDepositAmount;
  final double maximumDepositAmount;
  final bool requireDepositForAppointment;
  final List<PaymentMethod> enabledMethods;
  final Map<String, double> treatmentPrices;
  final String currency;
  final String bankName;
  final String bankAccountNumber;
  final String bankIban;

  PaymentSettings({
    this.appointmentDepositPercentage = 30.0,
    this.minimumDepositAmount = 50.0,
    this.maximumDepositAmount = 500.0,
    this.requireDepositForAppointment = false,
    this.enabledMethods = const [
      PaymentMethod.creditCard,
      PaymentMethod.debitCard,
      PaymentMethod.bankTransfer,
      PaymentMethod.cash,
    ],
    this.treatmentPrices = const {
      'Muayene': 200.0,
      'Temizlik': 300.0,
      'Dolgu': 400.0,
      'Kanal Tedavisi': 800.0,
      'Çekim': 250.0,
      'İmplant': 2500.0,
      'Beyazlatma': 600.0,
      'Ortodonti': 1500.0,
    },
    this.currency = 'TL',
    this.bankName = 'Türkiye İş Bankası',
    this.bankAccountNumber = '1234567890',
    this.bankIban = 'TR33 0006 1005 1978 6457 8413 26',
  });

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    return PaymentSettings(
      appointmentDepositPercentage:
          json['appointmentDepositPercentage']?.toDouble() ?? 30.0,
      minimumDepositAmount: json['minimumDepositAmount']?.toDouble() ?? 50.0,
      maximumDepositAmount: json['maximumDepositAmount']?.toDouble() ?? 500.0,
      requireDepositForAppointment:
          json['requireDepositForAppointment'] ?? false,
      enabledMethods:
          (json['enabledMethods'] as List<dynamic>?)
              ?.map(
                (e) => PaymentMethod.values.firstWhere(
                  (method) => method.name == e,
                ),
              )
              .toList() ??
          [
            PaymentMethod.creditCard,
            PaymentMethod.debitCard,
            PaymentMethod.bankTransfer,
            PaymentMethod.cash,
          ],
      treatmentPrices: json['treatmentPrices'] != null
          ? Map<String, double>.from(
              json['treatmentPrices'].map((k, v) => MapEntry(k, v.toDouble())),
            )
          : {
              'Muayene': 200.0,
              'Temizlik': 300.0,
              'Dolgu': 400.0,
              'Kanal Tedavisi': 800.0,
              'Çekim': 250.0,
              'İmplant': 2500.0,
              'Beyazlatma': 600.0,
              'Ortodonti': 1500.0,
            },
      currency: json['currency'] ?? 'TL',
      bankName: json['bankName'] ?? 'Türkiye İş Bankası',
      bankAccountNumber: json['bankAccountNumber'] ?? '1234567890',
      bankIban: json['bankIban'] ?? 'TR33 0006 1005 1978 6457 8413 26',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentDepositPercentage': appointmentDepositPercentage,
      'minimumDepositAmount': minimumDepositAmount,
      'maximumDepositAmount': maximumDepositAmount,
      'requireDepositForAppointment': requireDepositForAppointment,
      'enabledMethods': enabledMethods.map((e) => e.name).toList(),
      'treatmentPrices': treatmentPrices,
      'currency': currency,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankIban': bankIban,
    };
  }
}
