import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/error_view.dart';
import 'kuis_screen.dart';
import 'materi_list_screen.dart';
import 'riwayat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>?> _profil = SupabaseService.fetchProfil();

  void _muatUlang() {
    setState(() => _profil = SupabaseService.fetchProfil());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Pembelajaran & Kuis'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => SupabaseService.logout(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profil,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _muatUlang);
          }

          final profil = snapshot.data;
          final nama = (profil?['nama'] as String?)?.trim() ?? '';
          final role = (profil?['role'] as String?) ?? 'siswa';
          final isGuru = role == 'guru';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                nama.isEmpty ? 'Halo!' : 'Halo, $nama',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text(isGuru ? 'Guru' : 'Siswa')),
              ),
              const SizedBox(height: 8),
              const _MenuTile(
                icon: Icons.menu_book,
                judul: 'Materi',
                keterangan: 'Baca modul pembelajaran',
                tujuan: MateriListScreen(),
              ),
              const _MenuTile(
                icon: Icons.quiz,
                judul: 'Kuis',
                keterangan: 'Kerjakan soal pilihan ganda',
                tujuan: KuisScreen(),
              ),
              const _MenuTile(
                icon: Icons.history,
                judul: 'Riwayat nilai',
                keterangan: 'Lihat hasil kuis sebelumnya',
                tujuan: RiwayatScreen(),
              ),
              // Fitur khusus guru (authorization). Diisi pada minggu 11.
              if (isGuru)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.edit_note, size: 32),
                    title: const Text('Kelola materi dan soal'),
                    subtitle: const Text('Khusus guru'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur ini dibuat minggu depan.')),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String keterangan;
  final Widget tujuan;

  const _MenuTile({
    required this.icon,
    required this.judul,
    required this.keterangan,
    required this.tujuan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, size: 32),
        title: Text(judul),
        subtitle: Text(keterangan),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => tujuan),
        ),
      ),
    );
  }
}
