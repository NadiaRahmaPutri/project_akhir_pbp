import 'package:flutter_test/flutter_test.dart';
import 'package:project_akhir_pbp/models/hasil_kuis.dart';

void main() {
  group('HasilKuis.skor', () {
    test('semua benar menghasilkan 100', () {
      final h = HasilKuis(waktu: DateTime(2026, 11, 13), benar: 5, total: 5);
      expect(h.skor, 100);
    });

    test('semua salah menghasilkan 0', () {
      final h = HasilKuis(waktu: DateTime(2026, 11, 13), benar: 0, total: 5);
      expect(h.skor, 0);
    });

    test('3 dari 4 benar menghasilkan 75', () {
      final h = HasilKuis(waktu: DateTime(2026, 11, 13), benar: 3, total: 4);
      expect(h.skor, 75);
    });

    test('2 dari 3 benar dibulatkan menjadi 67', () {
      final h = HasilKuis(waktu: DateTime(2026, 11, 13), benar: 2, total: 3);
      expect(h.skor, 67);
    });

    test('total 0 tidak menyebabkan pembagian nol', () {
      final h = HasilKuis(waktu: DateTime(2026, 11, 13), benar: 0, total: 0);
      expect(h.skor, 0);
    });
  });

  group('HasilKuis.fromMap', () {
    test('membaca data dari Supabase dengan benar', () {
      final h = HasilKuis.fromMap({
        'created_at': '2026-11-13T10:00:00Z',
        'benar': 4,
        'total': 5,
      });
      expect(h.benar, 4);
      expect(h.total, 5);
      expect(h.skor, 80);
    });
  });
}
