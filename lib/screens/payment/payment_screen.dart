import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../models/appointment.dart';
import '../../services/payment_service.dart';
import 'card_payment_screen.dart';
import 'bank_transfer_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Appointment appointment;
  final PaymentType paymentType;
  final double? customAmount;

  const PaymentScreen({
    super.key,
    required this.appointment,
    this.paymentType = PaymentType.appointmentDeposit,
    this.customAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();

  PaymentSettings? _paymentSettings;
  double _paymentAmount = 0.0;
  PaymentMethod? _selectedMethod;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    try {
      final settings = await _paymentService.getPaymentSettings();
      double amount;

      if (widget.customAmount != null) {
        amount = widget.customAmount!;
      } else if (widget.paymentType == PaymentType.appointmentDeposit) {
        amount = await _paymentService.calculateAppointmentDeposit(
          widget.appointment.treatmentType,
        );
      } else {
        amount = await _paymentService.getTreatmentPrice(
          widget.appointment.treatmentType,
        );
      }

      setState(() {
        _paymentSettings = settings;
        _paymentAmount = amount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme bilgileri yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _startPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ödeme yöntemi seçin')),
      );
      return;
    }

    try {
      // Ödeme kaydı oluştur
      final payment = await _paymentService.createPayment(
        userId: widget.appointment.userId,
        appointmentId: widget.appointment.id,
        doctorId: widget.appointment.doctorId ?? '',
        amount: _paymentAmount,
        type: widget.paymentType,
        method: _selectedMethod!,
        description:
            '${widget.appointment.treatmentType} - ${widget.paymentType.typeDisplayName}',
      );

      if (mounted) {
        // Ödeme yöntemine göre yönlendir
        switch (_selectedMethod!) {
          case PaymentMethod.creditCard:
          case PaymentMethod.debitCard:
            _navigateToCardPayment(payment);
            break;
          case PaymentMethod.bankTransfer:
            _navigateToBankTransfer(payment);
            break;
          case PaymentMethod.cash:
            _showCashPaymentDialog(payment);
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ödeme başlatılırken hata: $e')));
      }
    }
  }

  void _navigateToCardPayment(Payment payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardPaymentScreen(payment: payment),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  void _navigateToBankTransfer(Payment payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankTransferScreen(payment: payment),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showCashPaymentDialog(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nakit Ödeme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ödeme tutarı: ${_paymentAmount.toStringAsFixed(2)} ${_paymentSettings!.currency}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Nakit ödeme seçtiniz. Randevu sırasında kliniğimizde ödeme yapabilirsiniz.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Nakit ödeme için beklemede bırak
                await _paymentService.processPayment(payment.id);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nakit ödeme seçimi kaydedildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              }
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ödeme Özeti
            _buildPaymentSummary(),
            const SizedBox(height: 24),

            // Ödeme Yöntemi Seçimi
            _buildPaymentMethods(),
            const SizedBox(height: 32),

            // Ödeme Butonu
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Ödeme Özeti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSummaryRow('Hasta', widget.appointment.patientName),
            _buildSummaryRow(
              'Randevu Tarihi',
              DateFormat(
                'dd MMMM yyyy - HH:mm',
                'tr',
              ).format(widget.appointment.appointmentDate),
            ),
            _buildSummaryRow('Tedavi', widget.appointment.treatmentType),
            _buildSummaryRow('Ödeme Türü', widget.paymentType.typeDisplayName),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam Tutar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_paymentAmount.toStringAsFixed(2)} ${_paymentSettings!.currency}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Ödeme Yöntemi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...(_paymentSettings!.enabledMethods.map(
              (method) => _buildPaymentMethodTile(method),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedMethod == method;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.blue[50] : Colors.white,
      ),
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _selectedMethod,
        onChanged: (value) {
          setState(() {
            _selectedMethod = value;
          });
        },
        title: Row(
          children: [
            _getPaymentMethodIcon(method),
            const SizedBox(width: 12),
            Text(
              method.methodDisplayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue[700] : Colors.black87,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _getPaymentMethodDescription(method),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        activeColor: Colors.blue[600],
      ),
    );
  }

  Widget _getPaymentMethodIcon(PaymentMethod method) {
    IconData iconData;
    Color color;

    switch (method) {
      case PaymentMethod.creditCard:
        iconData = Icons.credit_card;
        color = Colors.blue[600]!;
        break;
      case PaymentMethod.debitCard:
        iconData = Icons.credit_card;
        color = Colors.green[600]!;
        break;
      case PaymentMethod.bankTransfer:
        iconData = Icons.account_balance;
        color = Colors.orange[600]!;
        break;
      case PaymentMethod.cash:
        iconData = Icons.money;
        color = Colors.grey[600]!;
        break;
    }

    return Icon(iconData, color: color, size: 24);
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Kredi kartı ile güvenli ödeme';
      case PaymentMethod.debitCard:
        return 'Banka kartı ile güvenli ödeme';
      case PaymentMethod.bankTransfer:
        return 'Havale/EFT ile ödeme';
      case PaymentMethod.cash:
        return 'Randevu sırasında nakit ödeme';
    }
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _selectedMethod != null ? _startPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock),
            const SizedBox(width: 8),
            Text(
              _selectedMethod == null
                  ? 'Ödeme Yöntemi Seçin'
                  : 'Güvenli Ödeme - ${_paymentAmount.toStringAsFixed(2)} ${_paymentSettings!.currency}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

extension PaymentTypeExtension on PaymentType {
  String get typeDisplayName {
    switch (this) {
      case PaymentType.appointmentDeposit:
        return 'Randevu Kaparası';
      case PaymentType.treatmentPayment:
        return 'Tedavi Ödemesi';
      case PaymentType.fullPayment:
        return 'Tam Ödeme';
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get methodDisplayName {
    switch (this) {
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
