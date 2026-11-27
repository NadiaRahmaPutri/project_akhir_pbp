import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../services/supabase_service.dart';
import '../widgets/error_view.dart';
import 'kelas_screen.dart';
import 'profil_screen.dart';
import 'siswa_kelas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>?> _profil = SupabaseService.fetchProfil();
  late Future<List<Kelas>> _kelas = KelasService.fetchKelas();

  void _muatUlang() {
    setState(() => _profil = SupabaseService.fetchProfil());
  }

  void _muatKelas() {
    setState(() => _kelas = KelasService.fetchKelas());
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), duration: const Duration(seconds: 8)),
    );
  }

  /// Mahasiswa yang NIM-nya masih kosong (akun lama) mengisinya di sini.
  Future<void> _isiNim() async {
    final ctrl = TextEditingController();
    final nim = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Isi NIM'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'NIM',
            hintText: 'Contoh: 2211001',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (nim == null || nim.isEmpty) return;

    try {
      await KelasService.perbaikiNim(nim);
      if (!mounted) return;
      _pesan('NIM tersimpan. Kelasmu akan muncul sesuai daftar dosen.');
      _muatUlang();
      _muatKelas();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan(e.message);
    } catch (_) {
      if (!mounted) return;
      _pesan('Gagal menyimpan NIM. Periksa koneksi internet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Pembelajaran & Kuis'),
        actions: [
          IconButton(
            tooltip: 'Akun saya',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilScreen()),
              );
              if (!mounted) return;
              _muatUlang();
              _muatKelas();
            },
          ),
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
              if (isGuru)
                const _MenuTile(
                  icon: Icons.class_,
                  judul: 'Kelas saya',
                  keterangan: 'Kelola materi, soal, dan nilai per kelas',
                  tujuan: KelasScreen(),
                )
              else ...[
                if (((profil?['nim'] as String?) ?? '').isEmpty) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('NIM belum diisi'),
                      subtitle: const Text(
                        'Isi NIM agar kelasmu muncul otomatis.',
                      ),
                      trailing: TextButton(
                        onPressed: _isiNim,
                        child: const Text('Isi NIM'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Kelas saya',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Kelas>>(
                  future: _kelas,
                  builder: (context, ks) {
                    if (ks.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (ks.hasError) {
                      return Card(
                        child: ListTile(
                          title: const Text('Gagal memuat kelas'),
                          subtitle:
                              const Text('Periksa koneksi, lalu coba lagi.'),
                          trailing: TextButton(
                            onPressed: _muatKelas,
                            child: const Text('Coba lagi'),
                          ),
                        ),
                      );
                    }
                    final daftar = ks.data ?? [];
                    if (daftar.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Belum ada kelas untukmu. Kelas muncul otomatis '
                            'setelah dosen memasukkan NIM-mu ke daftar kelas.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final k in daftar)
                          _MenuTile(
                            icon: Icons.class_,
                            judul: k.nama,
                            keterangan: 'Materi, kuis, dan riwayat nilai',
                            tujuan: SiswaKelasScreen(kelas: k),
                          ),
                      ],
                    );
                  },
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
                    isGuru ? 'Dosen' : 'Mahasiswa',
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