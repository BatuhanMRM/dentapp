import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../auth/login_screen.dart';
import '../patient/patient_panel_screen.dart';
import 'create_appointment_screen.dart';
import 'edit_appointment_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _appointmentService = AppointmentService();
  User? _currentUser;
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  bool _isLoading = true;
  AppointmentStatus _filterStatus = AppointmentStatus.all;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        await _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Veri yüklenirken hata: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppointments() async {
    if (_currentUser != null) {
      final appointments = await _appointmentService.getUserAppointments(
        _currentUser!.id,
      );
      _appointments = appointments;
      _applyFilter();
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
  }

  void _changeFilter(AppointmentStatus status) {
    setState(() {
      _filterStatus = status;
    });
    _applyFilter();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Eğer kullanıcı doktor ise, doktor panelini göster
    if (_currentUser != null && _currentUser!.isDoctor) {
      return DoctorDashboardScreen(doctor: _currentUser!);
    }

    // Eğer kullanıcı hasta ise, hasta panelini göster
    if (_currentUser != null && _currentUser!.isPatient) {
      return PatientPanelScreen(patient: _currentUser!);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Hoş geldin, ${_currentUser?.name ?? 'Kullanıcı'}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<AppointmentStatus>(
            icon: const Icon(Icons.filter_list),
            onSelected: (AppointmentStatus value) {
              _changeFilter(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.all,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.all)
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                    if (_filterStatus == AppointmentStatus.all) const SizedBox(width: 8),
                    Text(
                      'Tümü',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.all ? FontWeight.bold : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.all ? Colors.blue : Colors.black,
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
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                    if (_filterStatus == AppointmentStatus.pending)
                      const SizedBox(width: 8),
                    Text(
                      'Bekliyor',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.pending ? FontWeight.bold : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.pending ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.confirmed,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.confirmed)
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                    if (_filterStatus == AppointmentStatus.confirmed)
                      const SizedBox(width: 8),
                    Text(
                      'Onaylandı',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.confirmed ? FontWeight.bold : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.confirmed ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.completed,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.completed)
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                    if (_filterStatus == AppointmentStatus.completed)
                      const SizedBox(width: 8),
                    Text(
                      'Tamamlandı',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.completed ? FontWeight.bold : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.completed ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppointmentStatus>(
                value: AppointmentStatus.cancelled,
                child: Row(
                  children: [
                    if (_filterStatus == AppointmentStatus.cancelled)
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                    if (_filterStatus == AppointmentStatus.cancelled)
                      const SizedBox(width: 8),
                    Text(
                      'İptal Edildi',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.cancelled ? FontWeight.bold : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.cancelled ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: _filteredAppointments.isEmpty
            ? _buildEmptyState()
            : _buildAppointmentsList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CreateAppointmentScreen(userId: _currentUser!.id),
            ),
          );
          if (result == true) {
            _loadAppointments();
          }
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;

    if (_filterStatus == AppointmentStatus.all) {
      message = 'Henüz randevunuz yok';
      subtitle = 'Yeni randevu oluşturmak için + butonuna tıklayın';
    } else {
      switch (_filterStatus) {
        case AppointmentStatus.pending:
          message = 'Bekleyen randevunuz yok';
          subtitle = 'Bekleyen randevu bulunamadı';
          break;
        case AppointmentStatus.confirmed:
          message = 'Onaylanmış randevunuz yok';
          subtitle = 'Onaylanmış randevu bulunamadı';
          break;
        case AppointmentStatus.completed:
          message = 'Tamamlanmış randevunuz yok';
          subtitle = 'Tamamlanmış randevu bulunamadı';
          break;
        case AppointmentStatus.cancelled:
          message = 'İptal edilmiş randevunuz yok';
          subtitle = 'İptal edilmiş randevu bulunamadı';
          break;
        case AppointmentStatus.all:
          message = 'Henüz randevunuz yok';
          subtitle = 'Yeni randevu oluşturmak için + butonuna tıklayın';
          break;
      }
    }

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
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
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
        final isCancelled = appointment.status == AppointmentStatus.cancelled;

        return Opacity(
          opacity: isCancelled ? 0.6 : 1.0,
          child: Card(
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
                              appointment.treatmentType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment.patientName,
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
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appointment.timeSlot,
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

                  // Action Buttons
                  if (appointment.status != AppointmentStatus.completed &&
                      appointment.status != AppointmentStatus.cancelled) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCancelDialog(appointment),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('İptal Et'),
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
                            onPressed: () => _editAppointment(appointment),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Düzenle'),
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
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Randevu düzenleme
  Future<void> _editAppointment(Appointment appointment) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditAppointmentScreen(appointment: appointment),
      ),
    );

    if (result == true) {
      _loadAppointments();
    }
  }

  // Randevu iptal dialog
  Future<void> _showCancelDialog(Appointment appointment) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Randevu İptali'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Bu randevuyu iptal etmek istediğinizden emin misiniz?',
                ),
                const SizedBox(height: 8),
                Text(
                  '${appointment.treatmentType} - ${DateFormat('dd MMMM yyyy', 'tr').format(appointment.appointmentDate)} ${appointment.timeSlot}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu işlem geri alınamaz.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Vazgeç'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'İptal Et',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelAppointment(appointment);
              },
            ),
          ],
        );
      },
    );
  }

  // Randevu iptal etme
  Future<void> _cancelAppointment(Appointment appointment) async {
    try {
      final cancelledAppointment = appointment.copyWith(
        status: AppointmentStatus.cancelled,
      );

      await _appointmentService.updateAppointment(cancelledAppointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu başarıyla iptal edildi'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu iptal edilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
