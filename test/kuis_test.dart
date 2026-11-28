import 'package:flutter_test/flutter_test.dart';
import 'package:project_akhir_pbp/models/soal.dart';
import 'package:project_akhir_pbp/services/kuis_service.dart';

Map<String, dynamic> _data({
  String sekarang = '2026-12-02T10:00:00+00:00',
  int? percobaan,
  String? selesai,
}) =>
    {
      'kuis_id': 1,
      'judul': 'Kuis Minggu 1',
      'buka_pada': '2026-12-01T00:00:00+00:00',
      'tutup_pada': '2026-12-07T00:00:00+00:00',
      'acak': true,
      'jumlah_soal': 5,
      'total_waktu': 150,
      'percobaan_id': percobaan,
      'mulai_pada': percobaan == null ? null : '2026-12-02T09:00:00+00:00',
      'selesai_pada': selesai,
      'skor': selesai == null ? null : 80,
      'poin': selesai == null ? null : 4,
      'poin_maks': selesai == null ? null : 5,
      'sekarang': sekarang,
    };

void main() {
  group('Status kuis mahasiswa', () {
    test('dibuka di antara jadwal buka dan tutup', () {
      expect(KuisMahasiswa.fromMap(_data()).status, StatusKuis.dibuka);
    });

    test('belum dibuka sebelum jadwal', () {
      final k = KuisMahasiswa.fromMap(_data(sekarang: '2026-11-30T10:00:00+00:00'));
      expect(k.status, StatusKuis.belumDibuka);
    });

    test('ditutup setelah jadwal tutup bila tidak dikerjakan', () {
      final k = KuisMahasiswa.fromMap(_data(sekarang: '2026-12-08T10:00:00+00:00'));
      expect(k.status, StatusKuis.ditutup);
    });

    test('selesai menampilkan nilai walau kuis sudah ditutup', () {
      final k = KuisMahasiswa.fromMap(_data(
        sekarang: '2026-12-08T10:00:00+00:00',
        percobaan: 7,
        selesai: '2026-12-02T09:05:00+00:00',
      ));
      expect(k.status, StatusKuis.selesai);
      expect(k.skor, 80);
      expect(k.labelStatus, 'Selesai • Nilai 80');
    });

    test('sudah dimulai tetapi belum selesai tidak bisa dimulai lagi', () {
      final k = KuisMahasiswa.fromMap(_data(percobaan: 7));
      expect(k.status, StatusKuis.belumSelesai);
    });
  });

  group('Soal berbobot', () {
    test('bobot dibaca dari database', () {
      final s = Soal.fromMap({
        'id': 1,
        'pertanyaan': 'Pilih yang paling sesuai',
        'pilihan': ['A', 'B', 'C', 'D'],
        'bobot': [1, 4, 2, 0],
      });
      expect(s.bobot, [1, 4, 2, 0]);
      expect(s.bobotMaks, 4);
      expect(s.jawabanBenar, 1);
    });

    test('soal lama tanpa bobot memakai jawaban benar bobot 1', () {
      final s = Soal.fromMap({
        'id': 2,
        'pertanyaan': 'Soal lama',
        'pilihan': ['A', 'B', 'C'],
        'jawaban_benar': 2,
      });
      expect(s.bobot, [0, 0, 1]);
    });
  });
}
