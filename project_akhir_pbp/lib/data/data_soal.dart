import '../models/soal.dart';

// Data dummy minggu 9. Nanti diganti data dari database (minggu 10).
const List<Soal> dataSoal = [
  Soal(
    id: 1,
    pertanyaan: 'Bahasa pemrograman apa yang dipakai pada Flutter?',
    pilihan: ['Dart', 'Kotlin', 'Swift', 'Java'],
    jawabanBenar: 0,
  ),
  Soal(
    id: 2,
    pertanyaan:
        'Widget mana yang tampilannya bisa berubah saat state berubah?',
    pilihan: ['StatelessWidget', 'StatefulWidget', 'Container', 'Text'],
    jawabanBenar: 1,
  ),
  Soal(
    id: 3,
    pertanyaan: 'File apa yang berisi daftar dependency/package proyek Flutter?',
    pilihan: ['main.dart', 'README.md', 'pubspec.yaml', 'AndroidManifest.xml'],
    jawabanBenar: 2,
  ),
  Soal(
    id: 4,
    pertanyaan: 'Perintah apa untuk mengecek kesiapan lingkungan Flutter?',
    pilihan: ['flutter run', 'flutter doctor', 'flutter build', 'flutter clean'],
    jawabanBenar: 1,
  ),
  Soal(
    id: 5,
    pertanyaan: 'Widget mana yang menyusun anak-anaknya secara vertikal?',
    pilihan: ['Row', 'Stack', 'Column', 'Center'],
    jawabanBenar: 2,
  ),
];
