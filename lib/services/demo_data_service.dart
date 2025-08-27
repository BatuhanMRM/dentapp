import 'package:flutter/material.dart';
import '../../models/medical_record.dart';
import '../../models/patient_note.dart';
import '../../models/user.dart';
import '../../services/patient_tracking_service.dart';

class DemoDataService {
  static final _patientTrackingService = PatientTrackingService();

  static Future<void> addDemoData(String patientId) async {
    try {
      // Demo tıbbi kayıtları
      final demoRecords = [
        MedicalRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          patientId: patientId,
          doctorId: 'demo_doctor_1',
          doctorName: 'Dr. Ayşe Yılmaz',
          date: DateTime.now().subtract(const Duration(days: 30)),
          treatment: 'Diş Temizliği',
          diagnosis: 'Plak ve tartar birikimi',
          prescription: 'Ağız gargarası (günde 2 kez)',
          notes: 'Düzenli diş fırçalama önerildi',
          attachments: [],
          createdAt: DateTime.now(),
        ),
        MedicalRecord(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          patientId: patientId,
          doctorId: 'demo_doctor_2',
          doctorName: 'Dr. Mehmet Kaya',
          date: DateTime.now().subtract(const Duration(days: 60)),
          treatment: 'Kanal Tedavisi',
          diagnosis: 'Alt sol azı dişinde kök çürüğü',
          prescription: 'Ağrı kesici (ibuprofen 400mg)',
          notes: 'Kontrol randevusu 1 hafta sonra',
          attachments: ['rontgen_1.jpg', 'rontgen_2.jpg'],
          createdAt: DateTime.now(),
        ),
        MedicalRecord(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          patientId: patientId,
          doctorId: 'demo_doctor_1',
          doctorName: 'Dr. Ayşe Yılmaz',
          date: DateTime.now().subtract(const Duration(days: 90)),
          treatment: 'Dolgu',
          diagnosis: 'Üst sağ premolar çürük',
          prescription: '',
          notes: 'Kompozit dolgu yapıldı, sert yiyeceklerden kaçının',
          attachments: [],
          createdAt: DateTime.now(),
        ),
      ];

      // Demo hasta notları
      final demoNotes = [
        PatientNote(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          patientId: patientId,
          doctorId: 'demo_doctor_1',
          doctorName: 'Dr. Ayşe Yılmaz',
          title: 'Kontrol Randevusu',
          content: 'Kanal tedavisi sonrası kontrol için gelmeyi unutmayın',
          type: PatientNoteType.reminder,
          isCompleted: false,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          createdAt: DateTime.now(),
        ),
        PatientNote(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          patientId: patientId,
          doctorId: 'demo_doctor_2',
          doctorName: 'Dr. Mehmet Kaya',
          title: 'İlaç Kullanımı',
          content: 'Reçete edilen ağrı kesicileri günde 3 kez almayı unutmayın',
          type: PatientNoteType.prescription,
          isCompleted: true,
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now(),
        ),
        PatientNote(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          patientId: patientId,
          doctorId: 'demo_doctor_1',
          doctorName: 'Dr. Ayşe Yılmaz',
          title: 'Diş Fırçalama Hatırlatması',
          content:
              'Günde en az 2 kez diş fırçalamayı ve diş ipi kullanmayı unutmayın',
          type: PatientNoteType.reminder,
          isCompleted: false,
          dueDate: DateTime.now().add(const Duration(days: 1)),
          createdAt: DateTime.now(),
        ),
        PatientNote(
          id: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
          patientId: patientId,
          doctorId: 'demo_doctor_2',
          doctorName: 'Dr. Mehmet Kaya',
          title: 'Tedavi Takibi',
          content:
              'Dolgu sonrası herhangi bir hassasiyet yaşanırsa hemen başvurun',
          type: PatientNoteType.followUp,
          isCompleted: false,
          dueDate: DateTime.now().add(const Duration(days: 14)),
          createdAt: DateTime.now(),
        ),
      ];

      // Verileri kaydet
      for (final record in demoRecords) {
        await _patientTrackingService.addMedicalRecord(record);
      }

      for (final note in demoNotes) {
        await _patientTrackingService.addPatientNote(note);
      }
    } catch (e) {
      throw Exception('Demo veri eklenirken hata: $e');
    }
  }

  static void showDemoDataDialog(BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Veri Ekle'),
        content: const Text(
          'Hasta panelini test etmek için demo tıbbi kayıtlar ve notlar eklemek ister misiniz?\n\n'
          'Bu veriler sadece test amaçlıdır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await addDemoData(patientId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo veriler başarıyla eklendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Evet, Ekle'),
          ),
        ],
      ),
    );
  }
}
