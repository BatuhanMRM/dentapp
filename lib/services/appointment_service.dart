import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/appointment.dart';

class AppointmentService {
  static const String _appointmentsKey = 'appointments';

  // Mevcut randevuları yükle
  Future<List<Appointment>> getAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsData = prefs.getStringList(_appointmentsKey) ?? [];

    return appointmentsData
        .map((data) => Appointment.fromMap(jsonDecode(data)))
        .toList();
  }

  // Kullanıcının randevularını getir
  Future<List<Appointment>> getUserAppointments(String userId) async {
    final appointments = await getAppointments();
    return appointments.where((apt) => apt.userId == userId).toList();
  }

  // Tüm randevuları getir (doktor paneli için)
  Future<List<Appointment>> getAllAppointments() async {
    return await getAppointments();
  }

  // Doktora özel randevuları getir
  Future<List<Appointment>> getDoctorAppointments(String doctorId) async {
    final appointments = await getAppointments();
    return appointments.where((apt) => apt.doctorId == doctorId).toList();
  }

  // Yeni randevu ekle
  Future<bool> addAppointment(Appointment appointment) async {
    try {
      final appointments = await getAppointments();

      // Aynı doktor için aynı tarih ve saatte randevu var mı kontrol et
      final conflictingAppointment = appointments.any(
        (apt) =>
            apt.appointmentDate.day == appointment.appointmentDate.day &&
            apt.appointmentDate.month == appointment.appointmentDate.month &&
            apt.appointmentDate.year == appointment.appointmentDate.year &&
            apt.timeSlot == appointment.timeSlot &&
            apt.doctorId == appointment.doctorId && // Doktor kontrolü eklendi
            apt.status != AppointmentStatus.cancelled,
      );

      if (conflictingAppointment) {
        throw Exception('Bu doktor için bu tarih ve saatte zaten bir randevu bulunmaktadır');
      }

      appointments.add(appointment);
      await _saveAppointments(appointments);
      return true;
    } catch (e) {
      throw Exception('Randevu kaydedilemedi: ${e.toString()}');
    }
  }

  // Randevu güncelle
  Future<bool> updateAppointment(Appointment appointment) async {
    try {
      final appointments = await getAppointments();
      final index = appointments.indexWhere((apt) => apt.id == appointment.id);

      if (index == -1) {
        throw Exception('Randevu bulunamadı');
      }

      appointments[index] = appointment;
      await _saveAppointments(appointments);
      return true;
    } catch (e) {
      throw Exception('Randevu güncellenemedi: ${e.toString()}');
    }
  }

  // Randevu sil
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      final appointments = await getAppointments();
      appointments.removeWhere((apt) => apt.id == appointmentId);
      await _saveAppointments(appointments);
      return true;
    } catch (e) {
      throw Exception('Randevu silinemedi: ${e.toString()}');
    }
  }

  // Mevcut saatleri getir
  List<String> getAvailableTimeSlots() {
    return [
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
      '17:00',
    ];
  }

  // Tedavi türlerini getir
  List<String> getTreatmentTypes() {
    return [
      'Kontrol ve Muayene',
      'Diş Temizliği',
      'Dolgu',
      'Kanal Tedavisi',
      'Çekim',
      'Protez',
      'İmplant',
      'Ortodonti',
      'Estetik Diş Hekimliği',
      'Diğer',
    ];
  }

  // Belirli bir tarih için dolu saatleri getir (tüm doktorlar için)
  Future<List<String>> getBookedTimeSlots(DateTime date) async {
    final appointments = await getAppointments();
    return appointments
        .where(
          (apt) =>
              apt.appointmentDate.day == date.day &&
              apt.appointmentDate.month == date.month &&
              apt.appointmentDate.year == date.year &&
              apt.status != AppointmentStatus.cancelled,
        )
        .map((apt) => apt.timeSlot)
        .toList();
  }

  // Belirli bir doktor için belirli bir tarihte dolu saatleri getir
  Future<List<String>> getBookedTimeSlotsForDoctor(DateTime date, String doctorId) async {
    final appointments = await getAppointments();
    return appointments
        .where(
          (apt) =>
              apt.appointmentDate.day == date.day &&
              apt.appointmentDate.month == date.month &&
              apt.appointmentDate.year == date.year &&
              apt.doctorId == doctorId &&
              apt.status != AppointmentStatus.cancelled,
        )
        .map((apt) => apt.timeSlot)
        .toList();
  }

  // Randevuları kaydet
  Future<void> _saveAppointments(List<Appointment> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsData = appointments
        .map((apt) => jsonEncode(apt.toMap()))
        .toList();
    await prefs.setStringList(_appointmentsKey, appointmentsData);
  }
}
