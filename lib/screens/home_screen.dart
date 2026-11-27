import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/error_view.dart';
import 'kelas_screen.dart';
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
              _Sapaan(nama: nama, isGuru: isGuru),
              const SizedBox(height: 20),
              if (isGuru) ...const [
                // Menu khusus guru
                _MenuTile(
                  icon: Icons.class_,
                  judul: 'Kelas saya',
                  keterangan: 'Kelola materi, soal, dan nilai per kelas',
                  tujuan: KelasScreen(isGuru: true),
                ),
              ] else ...const [
                // Menu khusus siswa
                _MenuTile(
                  icon: Icons.login,
                  judul: 'Gabung kelas',
                  keterangan: 'Masukkan kode kelas dari guru',
                  tujuan: KelasScreen(isGuru: false),
                ),
                _MenuTile(
                  icon: Icons.menu_book,
                  judul: 'Materi',
                  keterangan: 'Baca modul pembelajaran',
                  tujuan: MateriListScreen(),
                ),
                _MenuTile(
                  icon: Icons.quiz,
                  judul: 'Kuis',
                  keterangan: 'Kerjakan soal pilihan ganda',
                  tujuan: KuisScreen(),
                ),
                _MenuTile(
                  icon: Icons.history,
                  judul: 'Riwayat nilai',
                  keterangan: 'Lihat hasil kuis kamu sendiri',
                  tujuan: RiwayatScreen(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Banner biru berisi sapaan dan peran pengguna.
class _Sapaan extends StatelessWidget {
  final String nama;
  final bool isGuru;

  const _Sapaan({required this.nama, required this.isGuru});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F80ED), Color(0xFF56A0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang,',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  nama.isEmpty ? 'Pengguna' : nama,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGuru ? 'Guru' : 'Siswa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isGuru ? Icons.school : Icons.auto_stories,
            size: 56,
            color: Colors.white54,
          ),
        ],
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
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE3EEFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          judul,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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