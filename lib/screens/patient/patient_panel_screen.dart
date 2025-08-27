import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';
import '../../models/patient_note.dart';
import '../../services/patient_tracking_service.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/demo_data_service.dart';
import '../auth/login_screen.dart';
import '../appointment/create_appointment_screen.dart';
import '../blog/blog_screen.dart';
import 'package:intl/intl.dart';

class PatientPanelScreen extends StatefulWidget {
  final User patient;

  const PatientPanelScreen({super.key, required this.patient});

  @override
  State<PatientPanelScreen> createState() => _PatientPanelScreenState();
}

class _PatientPanelScreenState extends State<PatientPanelScreen>
    with SingleTickerProviderStateMixin {
  final _patientTrackingService = PatientTrackingService();
  final _appointmentService = AppointmentService();
  final _authService = AuthService();

  late TabController _tabController;
  
  List<MedicalRecord> _medicalRecords = [];
  List<PatientNote> _patientNotes = [];
  List<Appointment> _appointments = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      final records = await _patientTrackingService.getMedicalRecords(widget.patient.id);
      final notes = await _patientTrackingService.getPatientNotes(widget.patient.id);
      final appointments = await _appointmentService.getUserAppointments(widget.patient.id);
      final summary = await _patientTrackingService.getPatientSummary(widget.patient.id);

      setState(() {
        _medicalRecords = records;
        _patientNotes = notes;
        _appointments = appointments;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken hata: $e')),
        );
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yaparken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('${widget.patient.name} - Hasta Paneli'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () {
              DemoDataService.showDemoDataDialog(context, widget.patient.id);
            },
            tooltip: 'Demo Veri Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Özet'),
            Tab(icon: Icon(Icons.medical_services), text: 'Tedavi Geçmişi'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Randevular'),
            Tab(icon: Icon(Icons.note), text: 'Notlar'),
            Tab(icon: Icon(Icons.article), text: 'Blog'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildMedicalHistoryTab(),
          _buildAppointmentsTab(),
          _buildNotesTab(),
          _buildBlogTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildStatsCards(),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoşgeldiniz, ${widget.patient.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diş sağlığınızı takip edin',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalAppointments = _appointments.length;
    final upcomingAppointments = _appointments
        .where((app) => app.appointmentDate.isAfter(DateTime.now()) && 
                       app.status != AppointmentStatus.cancelled)
        .length;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Tedavi',
                '${_summary['totalRecords'] ?? 0}',
                Icons.medical_services,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Bekleyen Notlar',
                '${_summary['pendingNotes'] ?? 0}',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Randevu',
                '$totalAppointments',
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Yaklaşan Randevu',
                '$upcomingAppointments',
                Icons.event_available,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentAppointments = _appointments
        .where((app) => app.appointmentDate.isAfter(DateTime.now()))
        .take(1)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            if (_medicalRecords.isEmpty && _patientNotes.isEmpty && _appointments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Henüz aktivite yok'),
                ),
              )
            else ...[
              if (_medicalRecords.isNotEmpty)
                _buildActivityItem(
                  'Son Tedavi',
                  _medicalRecords.first.treatment,
                  DateFormat('dd.MM.yyyy').format(_medicalRecords.first.date),
                  Icons.medical_services,
                  Colors.green,
                ),
              if (recentAppointments.isNotEmpty)
                _buildActivityItem(
                  'Yaklaşan Randevu',
                  recentAppointments.first.treatmentType,
                  DateFormat('dd.MM.yyyy').format(recentAppointments.first.appointmentDate),
                  Icons.calendar_today,
                  Colors.blue,
                ),
              if (_patientNotes.where((note) => !note.isCompleted).isNotEmpty)
                _buildActivityItem(
                  'Yaklaşan Not',
                  _patientNotes.where((note) => !note.isCompleted).first.title,
                  DateFormat('dd.MM.yyyy').format(_patientNotes.where((note) => !note.isCompleted).first.dueDate),
                  Icons.note,
                  Colors.orange,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String type, String title, String date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: _medicalRecords.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz tedavi geçmişi yok'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _medicalRecords.length,
              itemBuilder: (context, index) {
                final record = _medicalRecords[index];
                return _buildMedicalRecordCard(record);
              },
            ),
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.green[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.treatment,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd.MM.yyyy').format(record.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Doktor: ${record.doctorName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (record.diagnosis.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tanı: ${record.diagnosis}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (record.prescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medication, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reçete: ${record.prescription}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notlar: ${record.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (record.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: record.attachments.map((attachment) {
                  return Chip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: Text(
                      attachment.split('/').last,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPatientData,
        child: _appointments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('Henüz randevu yok'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _createNewAppointment(),
                      icon: const Icon(Icons.add),
                      label: const Text('Randevu Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  return _buildAppointmentCard(appointment);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewAppointment(),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Yeni Randevu',
      ),
    );
  }

  Future<void> _createNewAppointment() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateAppointmentScreen(userId: widget.patient.id),
      ),
    );

    if (result == true) {
      // Randevu oluşturulduysa verileri yenile
      _loadPatientData();
    }
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (appointment.status) {
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Bekliyor';
        statusIcon = Icons.schedule;
        break;
      case AppointmentStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Onaylandı';
        statusIcon = Icons.check_circle;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.blue;
        statusText = 'Tamamlandı';
        statusIcon = Icons.done_all;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'İptal Edildi';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Bilinmiyor';
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.treatmentType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd.MM.yyyy').format(appointment.appointmentDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  appointment.timeSlot,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (appointment.doctorName?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Doktor: ${appointment.doctorName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notlar: ${appointment.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: _patientNotes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz not yok'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _patientNotes.length,
              itemBuilder: (context, index) {
                final note = _patientNotes[index];
                return _buildNoteCard(note);
              },
            ),
    );
  }

  Widget _buildNoteCard(PatientNote note) {
    final isOverdue = note.dueDate.isBefore(DateTime.now()) && !note.isCompleted;
    final color = note.isCompleted 
        ? Colors.green 
        : isOverdue 
        ? Colors.red 
        : Colors.orange;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  note.isCompleted ? Icons.check_circle : Icons.schedule,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: note.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.type.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Doktor: ${note.doctorName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Hedef: ${DateFormat('dd.MM.yyyy').format(note.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (isOverdue) ...[
                  const Spacer(),
                  Text(
                    'GECİKMİŞ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogTab() {
    return const BlogScreen();
  }
}
