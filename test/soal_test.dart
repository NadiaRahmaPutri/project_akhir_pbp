import 'package:flutter_test/flutter_test.dart';
import 'package:project_akhir_pbp/models/soal.dart';

void main() {
  test('Soal.fromMap memetakan kolom dengan benar', () {
    final s = Soal.fromMap({
      'id': 1,
      'pertanyaan': 'Apa bahasa pemrograman Flutter?',
      'pilihan': ['Java', 'Dart', 'Kotlin'],
      'jawaban_benar': 1,
    });

    expect(s.id, 1);
    expect(s.pertanyaan, 'Apa bahasa pemrograman Flutter?');
    expect(s.pilihan.length, 3);
    expect(s.pilihan[s.jawabanBenar], 'Dart');
  });
}
