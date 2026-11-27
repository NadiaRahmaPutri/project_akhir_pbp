import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../widgets/error_view.dart';
import 'kelola_screen.dart';
import 'nilai_kelas_screen.dart';

/// Guru: memilih/membuat kelas, lalu mengelola materi, soal, dan nilai.
/// Siswa: memasukkan kode untuk bergabung ke kelas.
class KelasScreen extends StatefulWidget {
  final bool isGuru;

  const KelasScreen({super.key, required this.isGuru});

  @override
  State<KelasScreen> createState() => _KelasScreenState();
}

class _KelasScreenState extends State<KelasScreen> {
  late Future<List<Kelas>> _kelas = KelasService.fetchKelas();
  final _kodeCtrl = TextEditingController();
  bool _proses = false;

  @override
  void dispose() {
    _kodeCtrl.dispose();
    super.dispose();
  }

  void _muatUlang() {
    setState(() => _kelas = KelasService.fetchKelas());
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
        duration: const Duration(seconds: 10),
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
                  MaterialPageRoute(builder: (_) => const KelolaScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Nilai siswa'),
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
            labelText: 'Nama kelas',
            hintText: 'Contoh: Informatika A',
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
      final k = await KelasService.buatKelas(nama);
      if (!mounted) return;
      _pesan('Kelas dibuat. Kode: ${k.kode}');
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
            'Kelas "${k.nama}" akan dihapus beserta daftar anggotanya.'),
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

  Future<void> _gabung() async {
    final kode = _kodeCtrl.text.trim();
    if (kode.isEmpty) {
      _pesan('Masukkan kode kelas dulu.');
      return;
    }
    setState(() => _proses = true);
    try {
      final nama = await KelasService.gabung(kode);
      if (!mounted) return;
      _kodeCtrl.clear();
      _pesan('Berhasil bergabung ke kelas $nama');
      _muatUlang();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan(e.message);
    } catch (e) {
      if (!mounted) return;
      _pesan('Gagal bergabung: $e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guru = widget.isGuru;
    return Scaffold(
      appBar: AppBar(title: Text(guru ? 'Kelas saya' : 'Gabung kelas')),
      floatingActionButton: guru
          ? FloatingActionButton.extended(
              onPressed: _buatKelas,
              icon: const Icon(Icons.add),
              label: const Text('Buat kelas'),
            )
          : null,
      body: Column(
        children: [
          if (guru)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Ketuk kelas untuk mengelola materi, soal, dan nilai.',
                textAlign: TextAlign.center,
              ),
            ),
          if (!guru)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Kode kelas',
                        hintText: 'Contoh: K7M2QX',
                      ),
                      onSubmitted: (_) => _gabung(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _proses ? null : _gabung,
                    child: _proses
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Gabung'),
                  ),
                ],
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        guru
                            ? 'Belum ada kelas. Tekan "Buat kelas" untuk memulai.'
                            : 'Kamu belum bergabung ke kelas mana pun.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                        subtitle: guru ? Text('Kode: ${k.kode}') : null,
                        onTap: guru ? () => _bukaKelas(k) : null,
                        trailing: guru
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Salin kode',
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: k.kode));
                                      _pesan('Kode ${k.kode} disalin');
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus kelas',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _hapus(k),
                                  ),
                                ],
                              )
                            : null,
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