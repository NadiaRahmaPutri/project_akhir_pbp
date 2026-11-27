import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../services/supabase_service.dart';
import '../widgets/error_view.dart';

/// Halaman akun: nama, NIM, email, dan peran milik pengguna yang masuk.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  late Future<Map<String, dynamic>?> _profil = SupabaseService.fetchProfil();

  void _muat() {
    setState(() => _profil = SupabaseService.fetchProfil());
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), duration: const Duration(seconds: 8)),
    );
  }

  Future<void> _ubahNim(String nimSekarang) async {
    final ctrl = TextEditingController(text: nimSekarang);
    final nim = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(nimSekarang.isEmpty ? 'Isi NIM' : 'Ubah NIM'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'NIM',
            helperText: 'Setelah terdaftar di kelas, NIM terkunci.',
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
    if (nim == null || nim.isEmpty || nim == nimSekarang) return;

    try {
      await KelasService.perbaikiNim(nim);
      if (!mounted) return;
      _pesan('NIM tersimpan.');
      _muat();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan(e.message);
    } catch (_) {
      if (!mounted) return;
      _pesan('Gagal menyimpan NIM. Periksa koneksi internet.');
    }
  }

  Future<void> _keluar() async {
    await SupabaseService.logout();
    if (!mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Akun saya')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profil,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _muat);
          }

          final p = snapshot.data;
          final nama = ((p?['nama'] as String?) ?? '').trim();
          final nim = ((p?['nim'] as String?) ?? '').trim();
          final isDosen = (p?['role'] as String?) == 'guru';
          final tampilNama = nama.isEmpty ? 'Pengguna' : nama;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        child: Text(
                          tampilNama.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tampilNama,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(isDosen ? 'Dosen' : 'Mahasiswa'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Nama'),
                      subtitle: Text(tampilNama),
                    ),
                    if (!isDosen)
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('NIM'),
                        subtitle: Text(nim.isEmpty ? 'Belum diisi' : nim),
                        trailing: TextButton(
                          onPressed: () => _ubahNim(nim),
                          child: Text(nim.isEmpty ? 'Isi' : 'Ubah'),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _keluar,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
