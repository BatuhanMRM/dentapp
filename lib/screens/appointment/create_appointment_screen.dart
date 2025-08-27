import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../models/payment.dart';
import '../payment/payment_screen.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final String userId;

  const CreateAppointmentScreen({super.key, required this.userId});

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _appointmentService = AppointmentService();
  final _authService = AuthService();
  final _paymentService = PaymentService();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedTreatmentType;
  User? _selectedDoctor;
  List<User> _doctors = [];
  List<String> _availableTimeSlots = [];
  List<String> _bookedTimeSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await _authService.getDoctors();
      setState(() {
        _doctors = doctors;
      });

      // Doktor bulunamadıysa uyarı ver
      if (doctors.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Henüz kayıtlı doktor bulunmuyor'),
            backgroundColor: Colors.orange[600],
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doktorlar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: now,
      maxTime: now.add(const Duration(days: 365)),
      onConfirm: (date) async {
        setState(() {
          _selectedDate = date;
          _selectedTimeSlot = null; // Reset time slot when date changes
        });
        // Tarih değiştiğinde müsait saatleri yükle
        await _loadAvailableTimeSlots();
      },
      currentTime: now,
      locale: LocaleType.tr,
    );
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate != null && _selectedDoctor != null) {
      // Seçilen doktor için dolu saatleri getir
      _bookedTimeSlots = await _appointmentService.getBookedTimeSlotsForDoctor(
        _selectedDate!,
        _selectedDoctor!.id,
      );
      final allTimeSlots = _appointmentService.getAvailableTimeSlots();

      setState(() {
        _availableTimeSlots = allTimeSlots
            .where((slot) => !_bookedTimeSlots.contains(slot))
            .toList();
      });
    } else if (_selectedDate != null) {
      // Doktor seçilmemişse tüm saatleri göster
      final allTimeSlots = _appointmentService.getAvailableTimeSlots();
      setState(() {
        _availableTimeSlots = allTimeSlots;
      });
    }
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir tarih seçin')));
      return;
    }
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir saat seçin')));
      return;
    }
    if (_selectedTreatmentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tedavi türünü seçin')),
      );
      return;
    }
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kayıtlı bir doktor seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Doktorun hala kayıtlı olduğunu kontrol et
    final currentDoctors = await _authService.getDoctors();
    final doctorStillExists = currentDoctors.any(
      (doc) => doc.id == _selectedDoctor!.id,
    );

    if (!doctorStillExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seçilen doktor artık kayıtlı değil. Lütfen başka bir doktor seçin',
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _selectedDoctor = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        patientName: _patientNameController.text.trim(),
        patientPhone: _patientPhoneController.text.trim(),
        appointmentDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        treatmentType: _selectedTreatmentType!,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        doctorId: _selectedDoctor!.id,
        doctorName: _selectedDoctor!.name,
      );

      await _appointmentService.addAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );

        // Ödeme seçeneği sun
        _showPaymentOption(appointment);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Yeni Randevu'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Name
              _buildSectionTitle('Hasta Bilgileri'),
              _buildTextField(
                controller: _patientNameController,
                label: 'Hasta Adı Soyadı',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Hasta adı gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Patient Phone
              _buildTextField(
                controller: _patientPhoneController,
                label: 'Telefon Numarası',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon numarası gereklidir';
                  }
                  if (value.length < 10) {
                    return 'Geçerli bir telefon numarası giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Appointment Details
              _buildSectionTitle('Randevu Detayları'),

              // Doctor Selection
              _buildDoctorDropdown(),
              const SizedBox(height: 16),

              // Treatment Type
              _buildDropdown(
                label: 'Tedavi Türü',
                value: _selectedTreatmentType,
                items: _appointmentService.getTreatmentTypes(),
                onChanged: (value) {
                  setState(() {
                    _selectedTreatmentType = value;
                  });
                },
                icon: Icons.medical_services,
              ),
              const SizedBox(height: 16),

              // Date Selection
              _buildDateSelector(),
              const SizedBox(height: 16),

              // Time Slot Selection
              if (_selectedDate != null && _selectedDoctor != null) ...[
                _buildTimeSlotSelector(),
                const SizedBox(height: 16),
              ] else if (_selectedDate != null && _selectedDoctor == null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Müsait saatleri görmek için önce doktor seçin',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes
              _buildTextField(
                controller: _notesController,
                label: 'Notlar (İsteğe bağlı)',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Randevu Oluştur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(label),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
                isExpanded: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: _doctors.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.orange[600],
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kayıtlı doktor bulunamadı',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Önce doktor hesabı oluşturulmalıdır',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<User>(
                          value: _selectedDoctor,
                          hint: const Text('Kayıtlı doktorlardan seçin'),
                          items: _doctors.map((doctor) {
                            return DropdownMenuItem<User>(
                              value: doctor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    doctor.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (doctor.specialty != null)
                                    Text(
                                      doctor.specialty!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _doctors.isEmpty
                              ? null
                              : (User? value) async {
                                  // Seçilen doktorun hala geçerli olduğunu kontrol et
                                  if (value != null) {
                                    final currentDoctors = await _authService
                                        .getDoctors();
                                    final doctorExists = currentDoctors.any(
                                      (doc) => doc.id == value.id,
                                    );

                                    if (!doctorExists) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Bu doktor artık kayıtlı değil',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }

                                  setState(() {
                                    _selectedDoctor = value;
                                    _selectedTimeSlot =
                                        null; // Saat seçimini sıfırla
                                  });
                                  // Doktor değiştiğinde müsait saatleri yeniden yükle
                                  if (_selectedDate != null) {
                                    await _loadAvailableTimeSlots();
                                  }
                                },
                          isExpanded: true,
                        ),
                      ),
              ),
            ],
          ),
          if (_doctors.isNotEmpty && _selectedDoctor != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Doktor seçildi',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? 'Tarih Seçin'
                  : DateFormat('dd MMMM yyyy', 'tr').format(_selectedDate!),
              style: TextStyle(
                fontSize: 16,
                color: _selectedDate == null ? Colors.grey[600] : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Saat Seçin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_availableTimeSlots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              'Bu tarih için uygun saat bulunmuyor',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTimeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeSlot = slot;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[700] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _showPaymentOption(Appointment appointment) async {
    final settings = await _paymentService.getPaymentSettings();
    final depositAmount = await _paymentService.calculateAppointmentDeposit(
      appointment.treatmentType,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.blue),
            SizedBox(width: 8),
            Text('Ödeme Seçeneği'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Randevunuz başarıyla oluşturuldu!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Şimdi ne yapmak istersiniz?'),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Kapora Ödemesi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Randevunuzu garanti altına almak için ${depositAmount.toStringAsFixed(2)} ${settings.currency} kapora ödeyebilirsiniz.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Şimdi Değil'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPayment(appointment, PaymentType.appointmentDeposit);
            },
            icon: const Icon(Icons.payment),
            label: const Text('Kapora Öde'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment(Appointment appointment, PaymentType paymentType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentScreen(appointment: appointment, paymentType: paymentType),
      ),
    ).then((paymentResult) {
      if (paymentResult == true) {
        // Ödeme başarılı, ana ekrana dön
        Navigator.pop(context, true);
      } else {
        // Ödeme yapılmadı, yine de ana ekrana dön
        Navigator.pop(context, true);
      }
    });
  }
}
