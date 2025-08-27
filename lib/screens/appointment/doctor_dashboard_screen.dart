import 'package:flutter/material.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../auth/login_screen.dart';
import '../doctor/add_patient_note_screen.dart';
import 'package:intl/intl.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final User doctor;

  const DoctorDashboardScreen({super.key, required this.doctor});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _appointmentService = AppointmentService();
  final _authService = AuthService();
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  bool _isLoading = true;
  AppointmentStatus _filterStatus = AppointmentStatus.all;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      // Sadece bu doktora ait randevuları getir
      final appointments = await _appointmentService.getDoctorAppointments(
        widget.doctor.id,
      );
      setState(() {
        _appointments = appointments;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Randevular yüklenirken hata: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_filterStatus == AppointmentStatus.all) {
      _filteredAppointments = List.from(_appointments);
    } else {
      _filteredAppointments = _appointments
          .where((appointment) => appointment.status == _filterStatus)
          .toList();
    }
    // Tarihe göre sırala (en yakın tarih önce)
    _filteredAppointments.sort(
      (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
    );
  }

  void _changeFilter(AppointmentStatus status) {
    setState(() {
      _filterStatus = status;
    });
    _applyFilter();
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Çıkış yaparken hata: $e')));
      }
    }
  }

  Future<void> _navigateToAddNote() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddPatientNoteScreen(),
      ),
    );
    
    if (result == true) {
      // Not eklendi, randevuları yenile
      await _loadAppointments();
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Bekliyor';
      case AppointmentStatus.confirmed:
        return 'Onaylandı';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.cancelled:
        return 'İptal Edildi';
      case AppointmentStatus.all:
        return 'Tümü';
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.all:
        return Colors.grey;
    }
  }

  Future<void> _updateAppointmentStatus(
    Appointment appointment,
    AppointmentStatus newStatus,
  ) async {
    try {
      final updatedAppointment = appointment.copyWith(status: newStatus);
      await _appointmentService.updateAppointment(updatedAppointment);

      setState(() {
        final index = _appointments.indexWhere(
          (apt) => apt.id == appointment.id,
        );
        if (index != -1) {
          _appointments[index] = updatedAppointment;
        }
        _applyFilter();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Randevu durumu güncellendi: ${_getStatusText(newStatus)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu güncellenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Dr. ${widget.doctor.name} - Panel'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<AppointmentStatus>(
            icon: const Icon(Icons.filter_list),
            onSelected: _changeFilter,
            itemBuilder: (context) => [
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.all,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.all)
                      const Icon(Icons.check, size: 16, color: Colors.green),
                    if (_filterStatus == AppointmentStatus.all)
                      const SizedBox(width: 8),
                    Text(
                      'Tümü',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.all
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.pending,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.pending)
                      const Icon(Icons.check, size: 16, color: Colors.green),
                    if (_filterStatus == AppointmentStatus.pending)
                      const SizedBox(width: 8),
                    const Text('Bekliyor'),
                  ],
                ),
              ),
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.confirmed,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.confirmed)
                      const Icon(Icons.check, size: 16, color: Colors.green),
                    if (_filterStatus == AppointmentStatus.confirmed)
                      const SizedBox(width: 8),
                    const Text('Onaylandı'),
                  ],
                ),
              ),
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.completed,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.completed)
                      const Icon(Icons.check, size: 16, color: Colors.green),
                    if (_filterStatus == AppointmentStatus.completed)
                      const SizedBox(width: 8),
                    const Text('Tamamlandı'),
                  ],
                ),
              ),
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.cancelled,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.cancelled)
                      const Icon(Icons.check, size: 16, color: Colors.green),
                    if (_filterStatus == AppointmentStatus.cancelled)
                      const SizedBox(width: 8),
                    const Text('İptal Edildi'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Hastalara Not Yaz',
            onPressed: _navigateToAddNote,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text(
                    'Çıkış yapmak istediğinizden emin misiniz?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: _filteredAppointments.isEmpty
            ? _buildEmptyState()
            : _buildAppointmentsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = _filterStatus == AppointmentStatus.all
        ? 'Henüz randevu yok'
        : '${_getStatusText(_filterStatus)} durumunda randevu yok';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _filteredAppointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patientName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appointment.treatmentType,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(appointment.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'tr',
                      ).format(appointment.appointmentDate),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      appointment.timeSlot,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      appointment.patientPhone,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (appointment.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.notes,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],

                // Action Buttons for Doctor
                if (appointment.status == AppointmentStatus.pending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateAppointmentStatus(
                            appointment,
                            AppointmentStatus.cancelled,
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Reddet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateAppointmentStatus(
                            appointment,
                            AppointmentStatus.confirmed,
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Onayla'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (appointment.status == AppointmentStatus.confirmed) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                        appointment,
                        AppointmentStatus.completed,
                      ),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Tamamlandı Olarak İşaretle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
