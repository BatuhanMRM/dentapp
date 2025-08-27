import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;

  const EditAppointmentScreen({super.key, required this.appointment});

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _appointmentService = AppointmentService();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedTreatmentType;
  List<String> _availableTimeSlots = [];
  List<String> _bookedTimeSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Mevcut randevu bilgilerini form alanlarına yükle
    _patientNameController.text = widget.appointment.patientName;
    _patientPhoneController.text = widget.appointment.patientPhone;
    _notesController.text = widget.appointment.notes;
    _selectedDate = widget.appointment.appointmentDate;
    _selectedTimeSlot = widget.appointment.timeSlot;
    _selectedTreatmentType = widget.appointment.treatmentType;

    // Mevcut tarih için müsait saatleri yükle
    _loadAvailableTimeSlots();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
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
          // Tarih değişirse mevcut saat seçimini koru (eğer müsaitse)
        });
        await _loadAvailableTimeSlots();
      },
      currentTime: _selectedDate ?? now,
      locale: LocaleType.tr,
    );
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate != null) {
      _bookedTimeSlots = await _appointmentService.getBookedTimeSlots(
        _selectedDate!,
      );

      // Kendi randevusunu hariç tut (çünkü düzenliyoruz)
      _bookedTimeSlots.removeWhere(
        (slot) =>
            slot == widget.appointment.timeSlot &&
            _selectedDate!.day == widget.appointment.appointmentDate.day &&
            _selectedDate!.month == widget.appointment.appointmentDate.month &&
            _selectedDate!.year == widget.appointment.appointmentDate.year,
      );

      final allTimeSlots = _appointmentService.getAvailableTimeSlots();

      setState(() {
        _availableTimeSlots = allTimeSlots
            .where((slot) => !_bookedTimeSlots.contains(slot))
            .toList();

        // Eğer seçili saat artık müsait değilse, seçimi temizle
        if (_selectedTimeSlot != null &&
            !_availableTimeSlots.contains(_selectedTimeSlot)) {
          _selectedTimeSlot = null;
        }
      });
    }
  }

  Future<void> _updateAppointment() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedAppointment = widget.appointment.copyWith(
        patientName: _patientNameController.text.trim(),
        patientPhone: _patientPhoneController.text.trim(),
        appointmentDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        treatmentType: _selectedTreatmentType!,
        notes: _notesController.text.trim(),
      );

      await _appointmentService.updateAppointment(updatedAppointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
        title: const Text('Randevu Düzenle'),
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
              if (_selectedDate != null) ...[
                _buildTimeSlotSelector(),
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

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateAppointment,
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
                          'Randevuyu Güncelle',
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
}
