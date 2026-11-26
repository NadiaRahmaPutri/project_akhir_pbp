# Media Pembelajaran & Kuis

Aplikasi mobile cross-platform berbasis Flutter untuk belajar dan latihan soal. Siswa membaca materi dan mengerjakan kuis, sedangkan guru mengelola materi dan soal. Dibuat sebagai project akhir mata kuliah Pemrograman Berbasis Platform, Program Studi S1 Informatika, Universitas Negeri Padang.

## Anggota Tim
| Yuni Adila (24343067)| Auth & CRUD |
| Nadia Rahma Putri (24343067) | QA, Release & Code Review Engineer |

## Fitur
- Registrasi, login, dan logout (Supabase Auth).
- Hak akses berdasarkan peran (siswa dan guru). Menu Kelola hanya tampil untuk guru.
- Daftar materi dan detail materi.
- Kuis pilihan ganda, halaman hasil, dan riwayat nilai.
- Guru: tambah, ubah, dan hapus (CRUD) materi dan soal.
- Impor soal dari REST API Open Trivia DB.
- Validasi input dan penanganan error.

## Teknologi
- Flutter dan Dart
- Supabase (Auth, Database PostgreSQL, Row Level Security)
- REST API: Open Trivia DB (paket `http`)

## Struktur Project
```
lib/
├── config.dart        # URL dan key dibaca dari --dart-define
├── main.dart
├── models/            # Materi, Soal, HasilKuis
├── screens/           # Login, Home, Materi, Kuis, Hasil, Riwayat, Kelola
├── services/          # supabase_service, kelola_service, trivia_service
└── widgets/           # error_view
test/                  # pengujian unit dan widget
```

## Cara Menjalankan
Prasyarat: Flutter SDK stabil, Android Studio atau VS Code, dan emulator atau perangkat Android.

1. Clone repository dan masuk ke foldernya:
   ```bash
   git clone https://github.com/NadiaRahmaPutri/project_akhir_pbp.git
   cd project_akhir_pbp
   flutter pub get
   ```
2. Siapkan project Supabase sendiri, lalu ambil **Project URL** dan **Publishable key** dari Project Settings → API Keys. Jangan memakai secret key.
3. Jalankan aplikasi. Nilai URL dan key diberikan lewat `--dart-define` sehingga tidak tertulis di kode:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://<project-id>.supabase.co --dart-define=SUPABASE_KEY=<publishable-key>
   ```

## Build APK Release
```bash
flutter build apk --release --dart-define=SUPABASE_URL=https://<project-id>.supabase.co --dart-define=SUPABASE_KEY=<publishable-key>
```
Hasil: `build/app/outputs/flutter-apk/app-release.apk`. APK siap pakai tersedia di halaman [Releases](https://github.com/NadiaRahmaPutri/project_akhir_pbp/releases).

## Pengujian
```bash
flutter analyze
flutter test
```
Terdapat 16 pengujian otomatis (model, validasi, dan widget halaman login), semuanya lulus.

## Keamanan
- URL dan key Supabase tidak disimpan di repository (`String.fromEnvironment`).
- `.vscode/launch.json` masuk `.gitignore`.
- Akses data dibatasi dengan Row Level Security di Supabase.

## Alur Kerja Git
Setiap fitur dikerjakan di branch terpisah (`fitur/...`), digabung ke `main` lewat Pull Request, dan direview anggota tim lain.

## Skema Data
