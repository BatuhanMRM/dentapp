import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';

class BankTransferScreen extends StatefulWidget {
  final Payment payment;

  const BankTransferScreen({super.key, required this.payment});

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final PaymentService _paymentService = PaymentService();
  final _referenceController = TextEditingController();

  Map<String, String>? _bankInfo;
  bool _isLoading = true;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadBankInfo() async {
    try {
      final bankInfo = await _paymentService.getBankTransferInfo(
        widget.payment.id,
      );
      setState(() {
        _bankInfo = bankInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banka bilgileri yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _confirmTransfer() async {
    if (_referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen referans numarasını girin')),
      );
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    try {
      await _paymentService.confirmBankTransfer(
        widget.payment.id,
        _referenceController.text.trim(),
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ödeme Kaydedildi!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Havale/EFT bildiriminiz alındı. Ödemeniz onaylandıktan sonra bilgilendirileceksiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopyalandı'),
        duration: const Duration(seconds: 2),
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
        title: const Text('Havale/EFT'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ödeme Bilgileri
            _buildPaymentInfo(),
            const SizedBox(height: 24),

            // Banka Bilgileri
            _buildBankInfo(),
            const SizedBox(height: 24),

            // Referans Numarası Girişi
            _buildReferenceInput(),
            const SizedBox(height: 24),

            // Önemli Notlar
            _buildImportantNotes(),
            const SizedBox(height: 32),

            // Onay Butonu
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[400]!, Colors.orange[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Ödeme Bilgileri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ödenecek Tutar:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  '${_bankInfo!['amount']} ${_bankInfo!['currency']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Açıklama: ${_bankInfo!['description']}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfo() {
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
                Icon(Icons.account_balance_wallet, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Banka Hesap Bilgileri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildCopyableField('Banka Adı', _bankInfo!['bankName']!),
            _buildCopyableField('Hesap Numarası', _bankInfo!['accountNumber']!),
            _buildCopyableField('IBAN', _bankInfo!['iban']!),
            _buildCopyableField(
              'Tutar',
              '${_bankInfo!['amount']} ${_bankInfo!['currency']}',
            ),
            _buildCopyableField('Açıklama', _bankInfo!['description']!),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          icon: Icon(Icons.copy, color: Colors.blue[600]),
          onPressed: () => _copyToClipboard(value, label),
          tooltip: 'Kopyala',
        ),
      ),
    );
  }

  Widget _buildReferenceInput() {
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
                Icon(Icons.receipt_long, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Havale/EFT Bildirimi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ödemenizi yaptıktan sonra aşağıya referans numarasını (dekont numarası) girin:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Referans/Dekont Numarası',
                hintText: 'Örnek: 123456789',
                prefixIcon: const Icon(Icons.confirmation_number),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    // QR kod okuyucu açılabilir
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'QR kod okuyucu özelliği yakında eklenecek',
                        ),
                      ),
                    );
                  },
                  tooltip: 'QR Kod Okut',
                ),
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotes() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Önemli Bilgiler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNoteItem(
              'Havale/EFT açıklama kısmına mutlaka belirtilen açıklamayı yazın',
            ),
            _buildNoteItem('Ödemeniz 1-2 iş günü içinde hesabımıza geçecektir'),
            _buildNoteItem(
              'Ödeme onaylandıktan sonra size bilgilendirme yapılacaktır',
            ),
            _buildNoteItem(
              'Sorun yaşarsanız müşteri hizmetlerimizle iletişime geçin',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.amber[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isConfirming ? null : _confirmTransfer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
        ),
        child: _isConfirming
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Kaydediliyor...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check),
                  SizedBox(width: 8),
                  Text(
                    'Ödeme Bildirimini Gönder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
