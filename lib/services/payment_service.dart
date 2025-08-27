import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment.dart';

class PaymentService {
  static const String _paymentsKey = 'payments';
  static const String _paymentSettingsKey = 'payment_settings';

  // Ödeme ayarlarını getir
  Future<PaymentSettings> getPaymentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsData = prefs.getString(_paymentSettingsKey);

    if (settingsData != null) {
      return PaymentSettings.fromJson(json.decode(settingsData));
    }

    // Varsayılan ayarlar
    final defaultSettings = PaymentSettings();
    await savePaymentSettings(defaultSettings);
    return defaultSettings;
  }

  // Ödeme ayarlarını kaydet
  Future<void> savePaymentSettings(PaymentSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paymentSettingsKey, json.encode(settings.toJson()));
  }

  // Randevu kaparası hesapla
  Future<double> calculateAppointmentDeposit(String treatmentType) async {
    final settings = await getPaymentSettings();
    final treatmentPrice = settings.treatmentPrices[treatmentType] ?? 200.0;

    double depositAmount =
        treatmentPrice * (settings.appointmentDepositPercentage / 100);

    // Minimum ve maksimum kontrolleri
    if (depositAmount < settings.minimumDepositAmount) {
      depositAmount = settings.minimumDepositAmount;
    }
    if (depositAmount > settings.maximumDepositAmount) {
      depositAmount = settings.maximumDepositAmount;
    }

    return depositAmount;
  }

  // Tedavi ücreti getir
  Future<double> getTreatmentPrice(String treatmentType) async {
    final settings = await getPaymentSettings();
    return settings.treatmentPrices[treatmentType] ?? 200.0;
  }

  // Ödeme oluştur
  Future<Payment> createPayment({
    required String userId,
    required String appointmentId,
    required String doctorId,
    required double amount,
    required PaymentType type,
    required PaymentMethod method,
    String? description,
  }) async {
    final payment = Payment(
      id: _generatePaymentId(),
      userId: userId,
      appointmentId: appointmentId,
      doctorId: doctorId,
      amount: amount,
      currency: 'TL',
      type: type,
      status: PaymentStatus.pending,
      method: method,
      description: description,
      createdAt: DateTime.now(),
    );

    await _savePayment(payment);
    return payment;
  }

  // Ödeme işlemini tamamla (simüle)
  Future<Payment> processPayment(String paymentId) async {
    final payment = await getPaymentById(paymentId);
    if (payment == null) {
      throw Exception('Ödeme bulunamadı');
    }

    // Simüle edilmiş ödeme işlemi
    await Future.delayed(const Duration(seconds: 2));

    // %95 başarı oranı ile simülasyon
    final random = Random();
    final isSuccess = random.nextDouble() > 0.05;

    final updatedPayment = payment.copyWith(
      status: isSuccess ? PaymentStatus.completed : PaymentStatus.failed,
      paidAt: isSuccess ? DateTime.now() : null,
      transactionId: isSuccess ? _generateTransactionId() : null,
    );

    await _savePayment(updatedPayment);
    return updatedPayment;
  }

  // Kredi kartı ile ödeme
  Future<Payment> processCardPayment({
    required String paymentId,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
  }) async {
    // Kart bilgilerini doğrula
    if (!_validateCardNumber(cardNumber)) {
      throw Exception('Geçersiz kart numarası');
    }
    if (!_validateExpiryDate(expiryDate)) {
      throw Exception('Geçersiz son kullanma tarihi');
    }
    if (!_validateCVV(cvv)) {
      throw Exception('Geçersiz CVV');
    }

    final payment = await getPaymentById(paymentId);
    if (payment == null) {
      throw Exception('Ödeme bulunamadı');
    }

    // Ödeme işlemini başlat
    final updatedPayment = payment.copyWith(
      status: PaymentStatus.processing,
      metadata: {
        'cardLastFourDigits': cardNumber.substring(cardNumber.length - 4),
        'cardHolderName': cardHolderName,
      },
    );
    await _savePayment(updatedPayment);

    // Simüle edilmiş banka işlemi
    await Future.delayed(const Duration(seconds: 3));

    return await processPayment(paymentId);
  }

  // Havale/EFT bilgileri getir
  Future<Map<String, String>> getBankTransferInfo(String paymentId) async {
    final payment = await getPaymentById(paymentId);
    final settings = await getPaymentSettings();

    if (payment == null) {
      throw Exception('Ödeme bulunamadı');
    }

    return {
      'bankName': settings.bankName,
      'accountNumber': settings.bankAccountNumber,
      'iban': settings.bankIban,
      'amount': payment.amount.toStringAsFixed(2),
      'currency': payment.currency,
      'description':
          'Randevu ID: ${payment.appointmentId} - ${payment.description ?? 'Ödeme'}',
      'paymentId': paymentId,
    };
  }

  // Havale ödemesini onayla
  Future<Payment> confirmBankTransfer(
    String paymentId,
    String referenceNumber,
  ) async {
    final payment = await getPaymentById(paymentId);
    if (payment == null) {
      throw Exception('Ödeme bulunamadı');
    }

    final updatedPayment = payment.copyWith(
      status: PaymentStatus.completed,
      paidAt: DateTime.now(),
      transactionId: referenceNumber,
      metadata: {
        'transferReference': referenceNumber,
        'confirmationMethod': 'manual',
      },
    );

    await _savePayment(updatedPayment);
    return updatedPayment;
  }

  // Ödeme iade et
  Future<Payment> refundPayment(String paymentId, String reason) async {
    final payment = await getPaymentById(paymentId);
    if (payment == null) {
      throw Exception('Ödeme bulunamadı');
    }

    if (payment.status != PaymentStatus.completed) {
      throw Exception('Sadece tamamlanmış ödemeler iade edilebilir');
    }

    final updatedPayment = payment.copyWith(
      status: PaymentStatus.refunded,
      refundedAt: DateTime.now(),
      refundReason: reason,
    );

    await _savePayment(updatedPayment);
    return updatedPayment;
  }

  // Tüm ödemeleri getir
  Future<List<Payment>> getAllPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsData = prefs.getStringList(_paymentsKey) ?? [];

    return paymentsData
        .map((data) => Payment.fromJson(json.decode(data)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Kullanıcının ödemelerini getir
  Future<List<Payment>> getUserPayments(String userId) async {
    final allPayments = await getAllPayments();
    return allPayments.where((payment) => payment.userId == userId).toList();
  }

  // Doktorun ödemelerini getir
  Future<List<Payment>> getDoctorPayments(String doctorId) async {
    final allPayments = await getAllPayments();
    return allPayments
        .where((payment) => payment.doctorId == doctorId)
        .toList();
  }

  // Randevu ödemelerini getir
  Future<List<Payment>> getAppointmentPayments(String appointmentId) async {
    final allPayments = await getAllPayments();
    return allPayments
        .where((payment) => payment.appointmentId == appointmentId)
        .toList();
  }

  // ID ile ödeme getir
  Future<Payment?> getPaymentById(String paymentId) async {
    final allPayments = await getAllPayments();
    try {
      return allPayments.firstWhere((payment) => payment.id == paymentId);
    } catch (e) {
      return null;
    }
  }

  // Ödeme istatistikleri
  Future<Map<String, dynamic>> getPaymentStatistics(String? doctorId) async {
    final payments = doctorId != null
        ? await getDoctorPayments(doctorId)
        : await getAllPayments();

    final completedPayments = payments.where(
      (p) => p.status == PaymentStatus.completed,
    );
    final totalAmount = completedPayments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
    final monthlyAmount = completedPayments
        .where(
          (p) =>
              p.paidAt != null &&
              p.paidAt!.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ),
        )
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);

    return {
      'totalPayments': payments.length,
      'completedPayments': completedPayments.length,
      'totalAmount': totalAmount,
      'monthlyAmount': monthlyAmount,
      'averagePayment': completedPayments.isNotEmpty
          ? totalAmount / completedPayments.length
          : 0.0,
      'pendingPayments': payments
          .where((p) => p.status == PaymentStatus.pending)
          .length,
      'failedPayments': payments
          .where((p) => p.status == PaymentStatus.failed)
          .length,
    };
  }

  // Ödeme kaydet
  Future<void> _savePayment(Payment payment) async {
    final allPayments = await getAllPayments();
    final index = allPayments.indexWhere((p) => p.id == payment.id);

    if (index >= 0) {
      allPayments[index] = payment;
    } else {
      allPayments.add(payment);
    }

    final prefs = await SharedPreferences.getInstance();
    final paymentsData = allPayments
        .map((p) => json.encode(p.toJson()))
        .toList();
    await prefs.setStringList(_paymentsKey, paymentsData);
  }

  // Yardımcı metodlar
  String _generatePaymentId() {
    return 'PAY_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  String _generateTransactionId() {
    return 'TXN_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999).toString().padLeft(6, '0')}';
  }

  bool _validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    return cleanNumber.length >= 13 && cleanNumber.length <= 19;
  }

  bool _validateExpiryDate(String expiryDate) {
    final regex = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
    if (!regex.hasMatch(expiryDate)) return false;

    final parts = expiryDate.split('/');
    final month = int.parse(parts[0]);
    final year = 2000 + int.parse(parts[1]);
    final now = DateTime.now();
    final expiryDateTime = DateTime(year, month + 1, 0);

    return expiryDateTime.isAfter(now);
  }

  bool _validateCVV(String cvv) {
    final cleanCVV = cvv.replaceAll(RegExp(r'\D'), '');
    return cleanCVV.length >= 3 && cleanCVV.length <= 4;
  }

  // Tedavi fiyatlarını güncelle
  Future<void> updateTreatmentPrice(String treatmentType, double price) async {
    final settings = await getPaymentSettings();
    final updatedPrices = Map<String, double>.from(settings.treatmentPrices);
    updatedPrices[treatmentType] = price;

    final updatedSettings = PaymentSettings(
      appointmentDepositPercentage: settings.appointmentDepositPercentage,
      minimumDepositAmount: settings.minimumDepositAmount,
      maximumDepositAmount: settings.maximumDepositAmount,
      requireDepositForAppointment: settings.requireDepositForAppointment,
      enabledMethods: settings.enabledMethods,
      treatmentPrices: updatedPrices,
      currency: settings.currency,
      bankName: settings.bankName,
      bankAccountNumber: settings.bankAccountNumber,
      bankIban: settings.bankIban,
    );

    await savePaymentSettings(updatedSettings);
  }
}
