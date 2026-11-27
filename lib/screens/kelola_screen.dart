import 'package:flutter/material.dart';
import '../models/materi.dart';
import '../models/soal.dart';
import '../services/kelola_service.dart';
import '../services/supabase_service.dart';
import '../services/trivia_service.dart';
import '../widgets/error_view.dart';
import 'materi_form_screen.dart';
import 'soal_form_screen.dart';

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

/// Halaman khusus guru: kelola materi dan soal.
class KelolaScreen extends StatelessWidget {
  const KelolaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola materi dan soal'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Materi'), Tab(text: 'Soal')],
          ),
        ),
        body: const TabBarView(children: [_TabMateri(), _TabSoal()]),
      ),
    );
  }
}

// ======================= TAB MATERI =======================
class _TabMateri extends StatefulWidget {
  const _TabMateri();

  @override
  State<_TabMateri> createState() => _TabMateriState();
}

class _TabMateriState extends State<_TabMateri> {
  late Future<List<Materi>> _future = SupabaseService.fetchMateri();

  void _muat() {
    setState(() => _future = SupabaseService.fetchMateri());
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

// ======================= TAB SOAL =======================
class _TabSoal extends StatefulWidget {
  const _TabSoal();

  @override
  State<_TabSoal> createState() => _TabSoalState();
}

class _TabSoalState extends State<_TabSoal> {
  late Future<List<Soal>> _future = SupabaseService.fetchSoal();
  bool _mengimpor = false;

  void _muat() {
    setState(() => _future = SupabaseService.fetchSoal());
  }

  Future<void> _buka([Soal? soal]) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SoalFormScreen(soal: soal)),
    );
    if (berubah == true && mounted) _muat();
  }

  Future<void> _hapus(Soal s) async {
    final yakin = await _konfirmasiHapus(context, s.pertanyaan);
    if (!yakin || !mounted) return;
    try {
      await KelolaService.hapusSoal(s.id);
      if (!mounted) return;
      _pesan(context, 'Soal dihapus.');
      _muat();
    } catch (_) {
      if (!mounted) return;
      _pesan(context, 'Gagal menghapus. Periksa koneksi internet.');
    }
  }

  /// Mengambil 5 soal dari REST API Open Trivia DB lalu menyimpannya ke Supabase.
  Future<void> _impor() async {
    setState(() => _mengimpor = true);
    try {
      final daftar = await TriviaService.ambilSoal(jumlah: 5);
      await KelolaService.imporSoal(daftar);
      if (!mounted) return;
      _pesan(context, '${daftar.length} soal berhasil diimpor.');
      _muat();
    } on TriviaException catch (e) {
      if (!mounted) return;
      _pesan(context, e.pesan);
    } catch (_) {
      if (!mounted) return;
      _pesan(context, 'Gagal menyimpan soal. Periksa koneksi internet.');
    } finally {
      if (mounted) setState(() => _mengimpor = false);
    }
  }

  String _jawabanBenar(Soal s) {
    if (s.jawabanBenar >= 0 && s.jawabanBenar < s.pilihan.length) {
      return s.pilihan[s.jawabanBenar];
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah soal',
        onPressed: () => _buka(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _mengimpor ? null : _impor,
                icon: _mengimpor
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download),
                label: const Text('Impor 5 soal dari Open Trivia DB'),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Soal>>(
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
                    child: Text('Belum ada soal. Tekan + untuk menambah.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: daftar.length,
                  itemBuilder: (context, i) {
                    final s = daftar[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          s.pertanyaan,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Jawaban benar: ${_jawabanBenar(s)} • Waktu: ${s.waktuDetik} detik',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _buka(s),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Ubah',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _buka(s),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _hapus(s),
                            ),
                          ],
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
