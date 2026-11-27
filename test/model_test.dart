import 'package:flutter_test/flutter_test.dart';
import 'package:project_akhir_pbp/models/hasil_kuis.dart';
import 'package:project_akhir_pbp/models/materi.dart';
import 'package:project_akhir_pbp/models/soal.dart';

void main() {
  group('HasilKuis', () {
    HasilKuis buat(int benar, int total) => HasilKuis(
          waktu: DateTime(2026, 11, 27),
          benar: benar,
          total: total,
        );

    test('skor dihitung 0-100 dan dibulatkan', () {
      expect(buat(8, 10).skor, 80);
      expect(buat(1, 3).skor, 33);
      expect(buat(2, 3).skor, 67);
      expect(buat(5, 5).skor, 100);
    });

    test('total 0 menghasilkan skor 0 tanpa error', () {
      expect(buat(0, 0).skor, 0);
    });

    test('fromMap membaca data dari database', () {
      final h = HasilKuis.fromMap({
        'created_at': '2026-11-27T12:00:00+00:00',
        'benar': 3,
        'total': 5,
      });
      expect(h.benar, 3);
      expect(h.total, 5);
      expect(h.skor, 60);
    });
  });

  group('Soal', () {
    test('waktu default 30 detik jika kolom kosong', () {
      final s = Soal.fromMap({
        'id': 1,
        'pertanyaan': 'Apa itu Flutter?',
        'pilihan': ['A', 'B', 'C'],
        'jawaban_benar': 1,
      });
      expect(s.waktuDetik, 30);
      expect(s.pilihan, ['A', 'B', 'C']);
      expect(s.jawabanBenar, 1);
    });

    test('waktu yang diatur dosen dipakai', () {
      final s = Soal.fromMap({
        'id': 2,
        'pertanyaan': 'Soal cepat',
        'pilihan': ['Ya', 'Tidak'],
        'jawaban_benar': 0,
        'waktu_detik': 45,
      });
      expect(s.waktuDetik, 45);
    });
  });

  group('Materi', () {
    test('kolom opsional kosong tidak menyebabkan error', () {
      final m = Materi.fromMap({'id': 1, 'judul': 'Pengenalan'});
      expect(m.judul, 'Pengenalan');
      expect(m.ringkasan, '');
      expect(m.isi, '');
      expect(m.gambarUrl, isNull);
    });

    test('alamat gambar terbaca', () {
      final m = Materi.fromMap({
        'id': 2,
        'judul': 'Bergambar',
        'ringkasan': 'r',
        'isi': 'i',
        'gambar_url': 'https://contoh.test/a.png',
      });
      expect(m.gambarUrl, 'https://contoh.test/a.png');
    });
  });
}