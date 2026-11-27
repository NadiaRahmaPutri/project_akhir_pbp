import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../widgets/error_view.dart';
import 'kelola_screen.dart';
import 'mahasiswa_kelas_screen.dart';
import 'nilai_kelas_screen.dart';

/// Dosen: memilih/membuat kelas, lalu mengelola materi, soal, daftar
/// mahasiswa, dan nilai. Mahasiswa masuk kelas otomatis lewat NIM.
class KelasScreen extends StatefulWidget {
  const KelasScreen({super.key});

  @override
  State<KelasScreen> createState() => _KelasScreenState();
}

class _KelasScreenState extends State<KelasScreen> {
  late Future<List<Kelas>> _kelas = KelasService.fetchKelas();

  void _muatUlang() {
    setState(() => _kelas = KelasService.fetchKelas());
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  void _bukaKelas(Kelas k) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                k.nama,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Kelola materi dan soal'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KelolaScreen(kelas: k),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.how_to_reg),
              title: const Text('Daftar mahasiswa'),
              subtitle: const Text('Tempel NIM dari Excel'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MahasiswaKelasScreen(kelas: k),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Nilai mahasiswa'),
              subtitle: const Text('Lihat nilai dan ekspor CSV'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NilaiKelasScreen(kelas: k),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _buatKelas() async {
    final ctrl = TextEditingController();
    final nama = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat kelas baru'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama kelas / mata kuliah',
            hintText: 'Contoh: Basis Data - A',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    if (nama == null || nama.isEmpty) return;

    try {
      await KelasService.buatKelas(nama);
      if (!mounted) return;
      _pesan('Kelas dibuat. Buka kelas lalu tempel daftar mahasiswa.');
      _muatUlang();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan('Gagal membuat kelas: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _pesan('Gagal membuat kelas: $e');
    }
  }

  Future<void> _hapus(Kelas k) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kelas?'),
        content: Text(
            'Kelas "${k.nama}" akan dihapus beserta anggota, materi, soal, dan nilainya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    try {
      await KelasService.hapusKelas(k.id);
      if (!mounted) return;
      _muatUlang();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan('Gagal menghapus kelas: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _pesan('Gagal menghapus kelas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelas saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _buatKelas,
        icon: const Icon(Icons.add),
        label: const Text('Buat kelas'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Ketuk kelas untuk mengelola materi, soal, daftar mahasiswa, dan nilai.',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Kelas>>(
              future: _kelas,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorView(onRetry: _muatUlang);
                }
                final daftar = snapshot.data ?? [];
                if (daftar.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada kelas. Tekan "Buat kelas" untuk memulai.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: daftar.length,
                  itemBuilder: (context, i) {
                    final k = daftar[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3EEFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.class_,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          k.nama,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _bukaKelas(k),
                        trailing: IconButton(
                          tooltip: 'Hapus kelas',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _hapus(k),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
