import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../services/kuis_service.dart';
import '../utils/format_waktu.dart';
import '../utils/unduh_csv.dart';
import '../widgets/error_view.dart';

class _Mhs {
  final String userId;
  final String nim;
  final String nama;
  final List<RekapBaris> kuis = [];

  _Mhs(this.userId, this.nim, this.nama);

  int get dikerjakan => kuis.where((b) => b.selesai).length;

  double? get rataRata {
    final nilai = kuis
        .where((b) => b.selesai && b.skor != null)
        .map((b) => b.skor!)
        .toList();
    if (nilai.isEmpty) return null;
    return nilai.reduce((a, b) => a + b) / nilai.length;
  }
}

/// Dosen: nilai semua mahasiswa per kuis dalam satu kelas, reset percobaan,
/// dan ekspor CSV.
class NilaiKelasScreen extends StatefulWidget {
  final Kelas kelas;

  const NilaiKelasScreen({super.key, required this.kelas});

  @override
  State<NilaiKelasScreen> createState() => _NilaiKelasScreenState();
}

class _NilaiKelasScreenState extends State<NilaiKelasScreen> {
  late Future<List<RekapBaris>> _data = KuisService.rekapKelas(widget.kelas.id);

  void _muatUlang() {
    setState(() {
      _data = KuisService.rekapKelas(widget.kelas.id);
    });
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), duration: const Duration(seconds: 8)),
    );
  }

  static List<_Mhs> _kelompok(List<RekapBaris> baris) {
    final peta = <String, _Mhs>{};
    for (final b in baris) {
      peta.putIfAbsent(b.userId, () => _Mhs(b.userId, b.nim, b.nama)).kuis.add(b);
    }
    return peta.values.toList();
  }

  static String _esc(String s) => '"${s.replaceAll('"', '""')}"';

  String _buatCsv(List<RekapBaris> baris) {
    final judul = <int, String>{};
    for (final b in baris) {
      judul.putIfAbsent(b.kuisId, () => b.kuisJudul);
    }
    final b = StringBuffer();
    b.writeln([
      'NIM',
      'Nama',
      ...judul.values.map(_esc),
      'Rata-rata',
    ].join(','));

    for (final m in _kelompok(baris)) {
      final skorPerKuis = <int, int?>{
        for (final r in m.kuis) r.kuisId: r.selesai ? r.skor : null,
      };
      final rata = m.rataRata;
      b.writeln([
        _esc(m.nim),
        _esc(m.nama),
        ...judul.keys.map((id) => skorPerKuis[id]?.toString() ?? ''),
        rata == null ? '' : rata.round().toString(),
      ].join(','));
    }
    return b.toString();
  }

  Future<void> _ekspor(List<RekapBaris> baris) async {
    final csv = _buatCsv(baris);
    final bersih = widget.kelas.nama.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final namaFile = 'nilai_$bersih.csv';
    final ok = await unduhCsv(namaFile, csv);
    if (!mounted) return;
    if (ok) {
      _pesan('File $namaFile diunduh.');
    } else {
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      _pesan('Data CSV disalin. Tempel di Excel atau catatan.');
    }
  }

  Future<void> _reset(_Mhs m, RekapBaris r) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset kuis?'),
        content: Text(
          '${m.nama} akan bisa mengerjakan "${r.kuisJudul}" lagi. '
          'Nilainya saat ini dihapus dari rekap (jejak reset tetap '
          'tersimpan di database).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    try {
      await KuisService.resetPercobaan(r.kuisId, r.userId);
      if (!mounted) return;
      _pesan('Kuis ${m.nama} direset. Ia bisa mengerjakan lagi.');
      _muatUlang();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan(e.message);
    } catch (_) {
      if (!mounted) return;
      _pesan('Gagal mereset. Periksa koneksi internet.');
    }
  }

  String _ringkas(RekapBaris r) {
    if (!r.adaPercobaan) return 'Belum dikerjakan';
    if (!r.selesai) return 'Belum selesai (kesempatan terpakai)';
    return 'Skor ${r.skor ?? 0} (poin ${r.poin ?? 0}/${r.poinMaks ?? 0}) • '
        '${tglJam(r.selesaiPada!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nilai: ${widget.kelas.nama}')),
      body: FutureBuilder<List<RekapBaris>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _muatUlang);
          }
          final baris = snapshot.data ?? [];
          if (baris.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada nilai untuk ditampilkan. Pastikan sudah ada '
                  'mahasiswa di Daftar mahasiswa dan kuis di tab Kuis.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = _kelompok(baris);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${data.length} mahasiswa',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _ekspor(baris),
                      icon: const Icon(Icons.download),
                      label: const Text('Ekspor CSV'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final m = data[i];
                    final rata = m.rataRata;
                    return Card(
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          m.nama,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${m.nim.isEmpty ? 'NIM belum diisi' : 'NIM ${m.nim}'} • '
                          '${m.dikerjakan}/${m.kuis.length} kuis'
                          '${rata == null ? '' : ' • rata-rata ${rata.round()}'}',
                        ),
                        children: [
                          for (final r in m.kuis)
                            ListTile(
                              dense: true,
                              title: Text(r.kuisJudul),
                              subtitle: Text(_ringkas(r)),
                              trailing: r.adaPercobaan
                                  ? IconButton(
                                      tooltip: 'Reset agar bisa dikerjakan lagi',
                                      icon: const Icon(Icons.restart_alt),
                                      onPressed: () => _reset(m, r),
                                    )
                                  : null,
                            ),
                        ],
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
