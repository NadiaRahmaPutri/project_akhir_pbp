import 'package:flutter/material.dart';
import '../models/soal.dart';
import '../services/kelas_service.dart';
import '../services/kelola_service.dart';
import '../services/kuis_service.dart';
import '../services/trivia_service.dart';
import '../utils/format_waktu.dart';
import '../widgets/error_view.dart';
import 'soal_form_screen.dart';

/// Dosen: isi satu kuis (daftar soal berbobot) dan impor soal.
class KuisKelolaScreen extends StatefulWidget {
  final Kelas kelas;
  final Kuis kuis;

  const KuisKelolaScreen({super.key, required this.kelas, required this.kuis});

  @override
  State<KuisKelolaScreen> createState() => _KuisKelolaScreenState();
}

class _KuisKelolaScreenState extends State<KuisKelolaScreen> {
  static const _huruf = ['A', 'B', 'C', 'D', 'E', 'F'];

  late Future<List<Soal>> _future = KuisService.fetchSoalKuis(widget.kuis.id);
  bool _mengimpor = false;

  void _muat() {
    setState(() {
      _future = KuisService.fetchSoalKuis(widget.kuis.id);
    });
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _buka([Soal? soal]) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SoalFormScreen(
          kelasId: widget.kelas.id,
          kuisId: widget.kuis.id,
          soal: soal,
        ),
      ),
    );
    if (berubah == true && mounted) _muat();
  }

  Future<void> _hapus(Soal s) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus soal?'),
        content: Text('"${s.pertanyaan}" akan dihapus permanen.'),
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
      await KelolaService.hapusSoal(s.id);
      if (!mounted) return;
      _pesan('Soal dihapus.');
      _muat();
    } catch (_) {
      if (!mounted) return;
      _pesan('Gagal menghapus. Periksa koneksi internet.');
    }
  }

  /// Mengambil 5 soal dari Open Trivia DB lalu menyimpannya ke kuis ini.
  Future<void> _impor() async {
    setState(() {
      _mengimpor = true;
    });
    try {
      final daftar = await TriviaService.ambilSoal(jumlah: 5);
      await KelolaService.imporSoal(widget.kelas.id, widget.kuis.id, daftar);
      if (!mounted) return;
      _pesan('${daftar.length} soal berhasil diimpor.');
      _muat();
    } on TriviaException catch (e) {
      if (!mounted) return;
      _pesan(e.pesan);
    } catch (_) {
      if (!mounted) return;
      _pesan('Gagal menyimpan soal. Periksa koneksi internet.');
    } finally {
      if (mounted) {
        setState(() {
          _mengimpor = false;
        });
      }
    }
  }

  String _ringkasBobot(Soal s) {
    final bagian = <String>[];
    for (var i = 0; i < s.bobot.length; i++) {
      final huruf = i < _huruf.length ? _huruf[i] : '${i + 1}';
      bagian.add('$huruf=${s.bobot[i]}');
    }
    return 'Bobot ${bagian.join(', ')} • ${s.waktuDetik} detik';
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kuis;
    return Scaffold(
      appBar: AppBar(title: Text(k.judul)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _buka(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah soal'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Jadwal: ${jadwalKuis(k.bukaPada, k.tutupPada)}'
                '${k.acak ? '\nSoal dan pilihan diacak' : ''}',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada soal. Tekan "Tambah soal" atau impor dari Open Trivia DB.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: daftar.length,
                  itemBuilder: (context, i) {
                    final s = daftar[i];
                    return Card(
                      child: ListTile(
                        isThreeLine: true,
                        title: Text(
                          s.pertanyaan,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _ringkasBobot(s),
                          maxLines: 2,
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
