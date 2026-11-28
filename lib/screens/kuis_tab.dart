import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../services/kuis_service.dart';
import '../utils/format_waktu.dart';
import '../widgets/error_view.dart';
import 'kuis_form_screen.dart';
import 'kuis_kelola_screen.dart';

/// Tab "Kuis" di halaman kelola dosen: daftar kuis per pertemuan.
class KuisTab extends StatefulWidget {
  final Kelas kelas;

  const KuisTab({super.key, required this.kelas});

  @override
  State<KuisTab> createState() => _KuisTabState();
}

class _KuisTabState extends State<KuisTab> {
  late Future<List<Kuis>> _future = KuisService.fetchKuisKelas(widget.kelas.id);

  void _muat() {
    setState(() {
      _future = KuisService.fetchKuisKelas(widget.kelas.id);
    });
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _form([Kuis? kuis]) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KuisFormScreen(kelas: widget.kelas, kuis: kuis),
      ),
    );
    if (berubah == true && mounted) _muat();
  }

  Future<void> _buka(Kuis kuis) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KuisKelolaScreen(kelas: widget.kelas, kuis: kuis),
      ),
    );
    if (mounted) _muat();
  }

  Future<void> _hapus(Kuis kuis) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kuis?'),
        content: Text(
          '"${kuis.judul}" dihapus beserta soal dan nilai mahasiswa di kuis ini.',
        ),
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
    if (yakin != true || !mounted) return;
    try {
      await KuisService.hapusKuis(kuis.id);
      if (!mounted) return;
      _pesan('Kuis dihapus.');
      _muat();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan('Gagal menghapus: ${e.message}');
    } catch (_) {
      if (!mounted) return;
      _pesan('Gagal menghapus. Periksa koneksi internet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Buat kuis'),
      ),
      body: FutureBuilder<List<Kuis>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _muat);
          }
          final daftar = snapshot.data ?? [];
          if (daftar.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada kuis. Tekan "Buat kuis", atur jadwalnya, '
                  'lalu tambahkan soal.',
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
                  isThreeLine: true,
                  title: Text(k.judul),
                  subtitle: Text(
                    '${jadwalKuis(k.bukaPada, k.tutupPada)}\n'
                    '${k.jumlahSoal} soal${k.acak ? ' • diacak' : ''}',
                  ),
                  onTap: () => _buka(k),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Ubah jadwal',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _form(k),
                      ),
                      IconButton(
                        tooltip: 'Hapus kuis',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _hapus(k),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
