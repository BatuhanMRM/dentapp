import 'package:dentapp/screens/payment/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? userId;
  final String? doctorId;

  const PaymentHistoryScreen({super.key, this.userId, this.doctorId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();

  List<Payment> _payments = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  PaymentStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      List<Payment> payments;
      Map<String, dynamic> stats;

      if (widget.userId != null) {
        payments = await _paymentService.getUserPayments(widget.userId!);
        stats = await _paymentService.getPaymentStatistics(null);
      } else if (widget.doctorId != null) {
        payments = await _paymentService.getDoctorPayments(widget.doctorId!);
        stats = await _paymentService.getPaymentStatistics(widget.doctorId!);
      } else {
        payments = await _paymentService.getAllPayments();
        stats = await _paymentService.getPaymentStatistics(null);
      }

      setState(() {
        _payments = payments;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme geçmişi yüklenirken hata: $e')),
        );
      }
    }
  }

  List<Payment> get _filteredPayments {
    if (_filterStatus == null) {
      return _payments;
    }
    return _payments
        .where((payment) => payment.status == _filterStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Geçmişi'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _filterStatus = null;
                } else {
                  _filterStatus = PaymentStatus.values.firstWhere(
                    (status) => status.toString().split('.').last == value,
                  );
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'all',
                child: Text('Tümü'),
              ),
              ...PaymentStatus.values.map(
                (status) => PopupMenuItem<String>(
                  value: status.toString().split('.').last,
                  child: Text(status.statusDisplayName),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPayments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İstatistikler
                    if (_statistics != null) ...[
                      _buildStatistics(),
                      const SizedBox(height: 24),
                    ],

                    // Ödeme Listesi
                    _buildPaymentsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatistics() {
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
                Icon(Icons.analytics, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Ödeme İstatistikleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Ödeme',
                    '${_statistics!['totalAmount'].toStringAsFixed(2)} TL',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Bu Ay',
                    '${_statistics!['monthlyAmount'].toStringAsFixed(2)} TL',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tamamlanan',
                    '${_statistics!['completedPayments']}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Bekleyen',
                    '${_statistics!['pendingPayments']}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    final filteredPayments = _filteredPayments;

    if (filteredPayments.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payment, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              'Ödemeler (${filteredPayments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_filterStatus != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(_filterStatus!.statusDisplayName),
                backgroundColor: _getStatusColor(
                  _filterStatus!,
                ).withOpacity(0.1),
                side: BorderSide(color: _getStatusColor(_filterStatus!)),
                onDeleted: () {
                  setState(() {
                    _filterStatus = null;
                  });
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredPayments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildPaymentCard(filteredPayments[index]);
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final statusColor = _getStatusColor(payment.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPaymentDetails(payment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      payment.status.statusDisplayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Payment Info
              Text(
                payment.description ?? 'Ödeme',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payment.type.typeDisplayName,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Meta Info
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    payment.method.methodDisplayName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                      'tr',
                    ).format(payment.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              // Transaction ID if available
              if (payment.transactionId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'İşlem: ${payment.transactionId}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filterStatus != null
                ? '${_filterStatus!.statusDisplayName} ödeme bulunamadı'
                : 'Henüz ödeme kaydı yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ödemeleriniz burada görünecek',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Ödeme Detayları',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),

              // Payment Details
              _buildDetailRow(
                'Tutar',
                '${payment.amount.toStringAsFixed(2)} ${payment.currency}',
              ),
              _buildDetailRow('Durum', payment.status.statusDisplayName),
              _buildDetailRow('Ödeme Türü', payment.type.typeDisplayName),
              _buildDetailRow(
                'Ödeme Yöntemi',
                payment.method.methodDisplayName,
              ),
              _buildDetailRow(
                'Oluşturma Tarihi',
                DateFormat(
                  'dd MMMM yyyy HH:mm',
                  'tr',
                ).format(payment.createdAt),
              ),

              if (payment.paidAt != null)
                _buildDetailRow(
                  'Ödeme Tarihi',
                  DateFormat(
                    'dd MMMM yyyy HH:mm',
                    'tr',
                  ).format(payment.paidAt!),
                ),

              if (payment.transactionId != null)
                _buildDetailRow('İşlem ID', payment.transactionId!),

              if (payment.description != null)
                _buildDetailRow('Açıklama', payment.description!),

              if (payment.refundReason != null) ...[
                _buildDetailRow('İade Nedeni', payment.refundReason!),
                if (payment.refundedAt != null)
                  _buildDetailRow(
                    'İade Tarihi',
                    DateFormat(
                      'dd MMMM yyyy HH:mm',
                      'tr',
                    ).format(payment.refundedAt!),
                  ),
              ],

              const SizedBox(height: 20),

              // Actions
              if (payment.status == PaymentStatus.completed &&
                  widget.doctorId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRefundDialog(payment),
                    icon: const Icon(Icons.undo),
                    label: const Text('İade Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog(Payment payment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme İadesi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${payment.amount.toStringAsFixed(2)} ${payment.currency} tutarındaki ödemeyi iade etmek istediğinizden emin misiniz?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'İade Nedeni',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İade nedeni gereklidir')),
                );
                return;
              }

              try {
                await _paymentService.refundPayment(
                  payment.id,
                  reasonController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  _loadPayments();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ödeme başarıyla iade edildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('İade işlemi başarısız: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('İade Et'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get statusDisplayName {
    switch (this) {
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
}
