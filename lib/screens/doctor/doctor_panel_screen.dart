import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../auth/login_screen.dart';

class DoctorPanelScreen extends StatefulWidget {
  const DoctorPanelScreen({super.key});

  @override
  State<DoctorPanelScreen> createState() => _DoctorPanelScreenState();
}

class _DoctorPanelScreenState extends State<DoctorPanelScreen> {
  final _authService = AuthService();
  final _appointmentService = AppointmentService();
  User? _currentUser;
  List<Appointment> _allAppointments = [];
  List<Appointment> _filteredAppointments = [];
  bool _isLoading = true;
  AppointmentStatus _filterStatus = AppointmentStatus.all;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        await _loadAllAppointments();
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

  Future<void> _loadAllAppointments() async {
    // Tüm randevuları al (doktor tüm randevuları görebilir)
    final appointments = await _appointmentService.getAllAppointments();
    _allAppointments = appointments;
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (_filterStatus == AppointmentStatus.all) {
        _filteredAppointments = List.from(_allAppointments);
      } else {
        _filteredAppointments = _allAppointments
            .where((appointment) => appointment.status == _filterStatus)
            .toList();
      }
    });
  }

  void _changeFilter(AppointmentStatus status) {
    setState(() {
      _filterStatus = status;
    });
    _applyFilter();
  }

  Future<void> _updateAppointmentStatus(
    Appointment appointment,
    AppointmentStatus newStatus,
  ) async {
    try {
      final updatedAppointment = appointment.copyWith(status: newStatus);
      await _appointmentService.updateAppointment(updatedAppointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Randevu durumu güncellendi: ${_getStatusText(newStatus)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durum güncellenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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
        title: Text(
          'Dr. ${_currentUser?.name ?? 'Kullanıcı'} - Randevu Paneli',
        ),
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
                        color: _filterStatus == AppointmentStatus.all
                            ? Colors.green
                            : Colors.black,
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
                    Text(
                      'Bekliyor',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.pending
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.pending
                            ? Colors.green
                            : Colors.black,
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
                      const Icon(Icons.check, size: 16, color: Colors.green),
                    if (_filterStatus == AppointmentStatus.confirmed)
                      const SizedBox(width: 8),
                    Text(
                      'Onaylandı',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.confirmed
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.confirmed
                            ? Colors.green
                            : Colors.black,
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
                      const Icon(Icons.check, size: 16, color: Colors.green),
                    if (_filterStatus == AppointmentStatus.completed)
                      const SizedBox(width: 8),
                    Text(
                      'Tamamlandı',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.completed
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.completed
                            ? Colors.green
                            : Colors.black,
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
                      const Icon(Icons.check, size: 16, color: Colors.green),
                    if (_filterStatus == AppointmentStatus.cancelled)
                      const SizedBox(width: 8),
                    Text(
                      'İptal Edildi',
                      style: TextStyle(
                        fontWeight: _filterStatus == AppointmentStatus.cancelled
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _filterStatus == AppointmentStatus.cancelled
                            ? Colors.green
                            : Colors.black,
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
        onRefresh: _loadAllAppointments,
        child: _filteredAppointments.isEmpty
            ? _buildEmptyState()
            : _buildAppointmentsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;

    if (_filterStatus == AppointmentStatus.all) {
      message = 'Henüz randevu yok';
      subtitle = 'Randevu talepleri buraya gelecek';
    } else {
      switch (_filterStatus) {
        case AppointmentStatus.pending:
          message = 'Bekleyen randevu yok';
          subtitle = 'Onay bekleyen randevu bulunamadı';
          break;
        case AppointmentStatus.confirmed:
          message = 'Onaylanmış randevu yok';
          subtitle = 'Onaylanmış randevu bulunamadı';
          break;
        case AppointmentStatus.completed:
          message = 'Tamamlanmış randevu yok';
          subtitle = 'Tamamlanmış randevu bulunamadı';
          break;
        case AppointmentStatus.cancelled:
          message = 'İptal edilmiş randevu yok';
          subtitle = 'İptal edilmiş randevu bulunamadı';
          break;
        case AppointmentStatus.all:
          message = 'Henüz randevu yok';
          subtitle = 'Randevu talepleri buraya gelecek';
          break;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
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
                              'Hasta: ${appointment.patientName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
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

                  // Doctor Action Buttons
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
                            icon: const Icon(Icons.cancel, size: 18),
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
          ),
        );
      },
    );
  }
}
