import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../widgets/error_view.dart';

/// Dosen: daftar mahasiswa satu kelas. Daftar ditempel dari Excel
/// (kolom NIM dan Nama). Mahasiswa yang NIM-nya cocok otomatis masuk kelas.
class MahasiswaKelasScreen extends StatefulWidget {
  final Kelas kelas;

  const MahasiswaKelasScreen({super.key, required this.kelas});

  @override
  State<MahasiswaKelasScreen> createState() => _MahasiswaKelasScreenState();
}

class _MahasiswaKelasScreenState extends State<MahasiswaKelasScreen> {
  late Future<List<MahasiswaKelas>> _data =
      KelasService.daftarMahasiswa(widget.kelas.id);
  bool _proses = false;

  void _muat() {
    setState(() => _data = KelasService.daftarMahasiswa(widget.kelas.id));
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), duration: const Duration(seconds: 8)),
    );
  }

  Future<void> _tempel() async {
    final ctrl = TextEditingController();
    final teks = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tempel daftar mahasiswa'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Salin dua kolom dari Excel (NIM lalu Nama), '
                'lalu tempel di bawah. Satu baris per mahasiswa.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '2211001  Nadia Putri\n2211002  Budi Santoso',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (teks == null || teks.trim().isEmpty) return;

    setState(() => _proses = true);
    try {
      final h = await KelasService.imporMahasiswa(widget.kelas.id, teks);
      if (!mounted) return;
      final lewat =
          h.dilewati > 0 ? ' ${h.dilewati} baris dilewati (format salah).' : '';
      _pesan(
        '${h.diproses} mahasiswa disimpan, ${h.terhubungBaru} langsung masuk kelas.$lewat',
      );
      _muat();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan(e.message);
    } catch (e) {
      if (!mounted) return;
      _pesan('Gagal menyimpan daftar: $e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Future<void> _hapus(MahasiswaKelas m) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluarkan dari kelas?'),
        content: Text(
            '${m.nama} (${m.nim}) tidak akan melihat kelas ini lagi. Nilainya tetap tersimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    try {
      await KelasService.hapusMahasiswa(widget.kelas.id, m.nim);
      if (!mounted) return;
      _pesan('${m.nama} dikeluarkan dari kelas.');
      _muat();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan(e.message);
    } catch (e) {
      if (!mounted) return;
      _pesan('Gagal menghapus: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mahasiswa: ${widget.kelas.nama}'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _muat,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _proses ? null : _tempel,
        icon: _proses
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.content_paste),
        label: const Text('Tempel daftar'),
      ),
      body: FutureBuilder<List<MahasiswaKelas>>(
        future: _data,
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
                  'Belum ada mahasiswa. Tekan "Tempel daftar" lalu tempel '
                  'kolom NIM dan Nama dari Excel.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final terdaftar = daftar.where((m) => m.sudahDaftar).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${daftar.length} mahasiswa • $terdaftar sudah punya akun',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: daftar.length,
                  itemBuilder: (context, i) {
                    final m = daftar[i];
                    return Card(
                      child: ListTile(
                        title: Text(m.nama),
                        subtitle: Text(
                          m.sudahDaftar
                              ? 'NIM ${m.nim} • Sudah punya akun'
                              : 'NIM ${m.nim} • Belum mendaftar',
                        ),
                        leading: Icon(
                          m.sudahDaftar
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: m.sudahDaftar
                              ? Colors.green
                              : Theme.of(context).disabledColor,
                        ),
                        trailing: IconButton(
                          tooltip: 'Keluarkan dari kelas',
                          icon: const Icon(Icons.person_remove_outlined),
                          onPressed: () => _hapus(m),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
