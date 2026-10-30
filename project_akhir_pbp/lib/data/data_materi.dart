import '../models/materi.dart';

// Data dummy minggu 9. Nanti diganti data dari database (minggu 10).
const List<Materi> dataMateri = [
  Materi(
    id: 1,
    judul: 'Pengenalan Flutter dan Dart',
    ringkasan: 'Apa itu Flutter, Dart, dan cara kerjanya.',
    isi:
        'Flutter adalah framework untuk membuat aplikasi mobile lintas platform '
        'dari satu kode program. Bahasa pemrogramannya adalah Dart.\n\n'
        'Tampilan aplikasi Flutter disusun dari widget. Widget bisa berupa teks, '
        'tombol, gambar, atau tata letak seperti Column dan Row.',
  ),
  Materi(
    id: 2,
    judul: 'StatelessWidget dan StatefulWidget',
    ringkasan: 'Perbedaan widget yang tetap dan widget yang bisa berubah.',
    isi:
        'StatelessWidget dipakai untuk tampilan yang tidak berubah setelah '
        'dibuat.\n\n'
        'StatefulWidget dipakai untuk tampilan yang bisa berubah ketika data '
        '(state) berubah. Perubahan state dipicu dengan setState().',
  ),
  Materi(
    id: 3,
    judul: 'Navigasi Antar Halaman',
    ringkasan: 'Berpindah halaman dengan Navigator.',
    isi:
        'Navigator.push digunakan untuk membuka halaman baru, dan '
        'Navigator.pop untuk kembali ke halaman sebelumnya.\n\n'
        'Setiap halaman biasanya dibuat sebagai widget terpisah di folder '
        'screens agar kode rapi.',
  ),
];
