import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medical_record.dart';
import '../models/patient_note.dart';
import '../models/appointment.dart';

class PatientTrackingService {
  static const String _medicalRecordsKey = 'medical_records';
  static const String _patientNotesKey = 'patient_notes';

  // Medical Records
  Future<List<MedicalRecord>> getMedicalRecords(String patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_medicalRecordsKey) ?? [];

      final records = recordsJson
          .map((json) => MedicalRecord.fromMap(jsonDecode(json)))
          .where((record) => record.patientId == patientId)
          .toList();

      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (e) {
      return [];
    }
  }

  Future<void> addMedicalRecord(MedicalRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_medicalRecordsKey) ?? [];

      recordsJson.add(jsonEncode(record.toMap()));
      await prefs.setStringList(_medicalRecordsKey, recordsJson);
    } catch (e) {
      throw Exception('Tıbbi kayıt eklenirken hata: $e');
    }
  }

  Future<void> updateMedicalRecord(MedicalRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_medicalRecordsKey) ?? [];

      final index = recordsJson.indexWhere((json) {
        final existingRecord = MedicalRecord.fromMap(jsonDecode(json));
        return existingRecord.id == record.id;
      });

      if (index != -1) {
        recordsJson[index] = jsonEncode(record.toMap());
        await prefs.setStringList(_medicalRecordsKey, recordsJson);
      }
    } catch (e) {
      throw Exception('Tıbbi kayıt güncellenirken hata: $e');
    }
  }

  Future<void> deleteMedicalRecord(String recordId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_medicalRecordsKey) ?? [];

      recordsJson.removeWhere((json) {
        final record = MedicalRecord.fromMap(jsonDecode(json));
        return record.id == recordId;
      });

      await prefs.setStringList(_medicalRecordsKey, recordsJson);
    } catch (e) {
      throw Exception('Tıbbi kayıt silinirken hata: $e');
    }
  }

  // Patient Notes
  Future<List<PatientNote>> getPatientNotes(String patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_patientNotesKey) ?? [];

      final notes = notesJson
          .map((json) => PatientNote.fromMap(jsonDecode(json)))
          .where((note) => note.patientId == patientId)
          .toList();

      notes.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return notes;
    } catch (e) {
      return [];
    }
  }

  Future<void> addPatientNote(PatientNote note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_patientNotesKey) ?? [];

      notesJson.add(jsonEncode(note.toMap()));
      await prefs.setStringList(_patientNotesKey, notesJson);
    } catch (e) {
      throw Exception('Not eklenirken hata: $e');
    }
  }

  Future<void> updatePatientNote(PatientNote note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_patientNotesKey) ?? [];

      final index = notesJson.indexWhere((json) {
        final existingNote = PatientNote.fromMap(jsonDecode(json));
        return existingNote.id == note.id;
      });

      if (index != -1) {
        notesJson[index] = jsonEncode(note.toMap());
        await prefs.setStringList(_patientNotesKey, notesJson);
      }
    } catch (e) {
      throw Exception('Not güncellenirken hata: $e');
    }
  }

  Future<void> deletePatientNote(String noteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_patientNotesKey) ?? [];

      notesJson.removeWhere((json) {
        final note = PatientNote.fromMap(jsonDecode(json));
        return note.id == noteId;
      });

      await prefs.setStringList(_patientNotesKey, notesJson);
    } catch (e) {
      throw Exception('Not silinirken hata: $e');
    }
  }

  // Comprehensive patient summary
  Future<Map<String, dynamic>> getPatientSummary(String patientId) async {
    try {
      final medicalRecords = await getMedicalRecords(patientId);
      final notes = await getPatientNotes(patientId);

      // Randevular için AppointmentService kullanılabilir
      final pendingNotes = notes.where((note) => !note.isCompleted).length;
      final completedTreatments = medicalRecords.length;

      return {
        'totalRecords': medicalRecords.length,
        'pendingNotes': pendingNotes,
        'completedNotes': notes.length - pendingNotes,
        'lastTreatment': medicalRecords.isNotEmpty
            ? medicalRecords.first.date
            : null,
        'nextDueNote': notes.where((note) => !note.isCompleted).isNotEmpty
            ? notes.where((note) => !note.isCompleted).first.dueDate
            : null,
      };
    } catch (e) {
      return {
        'totalRecords': 0,
        'pendingNotes': 0,
        'completedNotes': 0,
        'lastTreatment': null,
        'nextDueNote': null,
      };
    }
  }
}
