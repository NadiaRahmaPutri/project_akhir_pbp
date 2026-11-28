import 'package:flutter/material.dart';
import '../models/materi.dart';
import '../services/kelas_service.dart';
import '../services/kelola_service.dart';
import '../services/supabase_service.dart';
import '../widgets/error_view.dart';
import 'materi_form_screen.dart';
import 'kuis_tab.dart';

void _pesan(BuildContext context, String teks) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
}

Future<bool> _konfirmasiHapus(BuildContext context, String nama) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus data?'),
      content: Text('"$nama" akan dihapus permanen.'),
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
  return hasil == true;
}

/// Halaman dosen: kelola materi dan kuis (beserta soalnya) untuk satu kelas.
class KelolaScreen extends StatefulWidget {
  final Kelas kelas;

  const KelolaScreen({super.key, required this.kelas});

  @override
  State<KelolaScreen> createState() => _KelolaScreenState();
}

class _KelolaScreenState extends State<KelolaScreen> {
  @override
  void initState() {
    super.initState();
    // Form tambah materi/soal memakai kelas ini.
    KelolaService.kelasAktifId = widget.kelas.id;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Kelola: ${widget.kelas.nama}'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Materi'), Tab(text: 'Kuis')],
          ),
        ),
        body: TabBarView(
          children: [
            _TabMateri(kelasId: widget.kelas.id),
            KuisTab(kelas: widget.kelas),
          ],
        ),
      ),
    );
  }
}

// ======================= TAB MATERI =======================
class _TabMateri extends StatefulWidget {
  final int kelasId;

  const _TabMateri({required this.kelasId});

  @override
  State<_TabMateri> createState() => _TabMateriState();
}

class _TabMateriState extends State<_TabMateri> {
  late Future<List<Materi>> _future =
      SupabaseService.fetchMateri(widget.kelasId);

  void _muat() {
    setState(() { _future = SupabaseService.fetchMateri(widget.kelasId); });
  }

  Future<void> _buka([Materi? materi]) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MateriFormScreen(materi: materi)),
    );
    if (berubah == true && mounted) _muat();
  }

  Future<void> _hapus(Materi m) async {
    final yakin = await _konfirmasiHapus(context, m.judul);
    if (!yakin || !mounted) return;
    try {
      await KelolaService.hapusMateri(m.id);
      if (!mounted) return;
      _pesan(context, 'Materi dihapus.');
      _muat();
    } catch (_) {
      if (!mounted) return;
      _pesan(context, 'Gagal menghapus. Periksa koneksi internet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah materi',
        onPressed: () => _buka(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Materi>>(
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
              child: Text('Belum ada materi. Tekan + untuk menambah.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: daftar.length,
            itemBuilder: (context, i) {
              final m = daftar[i];
              return Card(
                child: ListTile(
                  title: Text(m.judul),
                  subtitle: Text(
                    m.ringkasan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _buka(m),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Ubah',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _buka(m),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _hapus(m),
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
