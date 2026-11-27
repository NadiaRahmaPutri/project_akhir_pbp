import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../utils/unduh_csv.dart';
import '../widgets/error_view.dart';

class _Percobaan {
  final int benar;
  final int total;
  final DateTime? waktu;

  const _Percobaan({required this.benar, required this.total, this.waktu});

  double get skor => total == 0 ? 0 : benar / total * 100;
}

class _Rekap {
  final String nama;
  final List<_Percobaan> percobaan = [];

  _Rekap(this.nama);

  double get rataRata => percobaan.isEmpty
      ? 0
      : percobaan.map((p) => p.skor).reduce((a, b) => a + b) /
          percobaan.length;
}

/// Guru: nilai semua siswa dalam satu kelas, plus ekspor CSV.
class NilaiKelasScreen extends StatefulWidget {
  final Kelas kelas;

  const NilaiKelasScreen({super.key, required this.kelas});

  @override
  State<NilaiKelasScreen> createState() => _NilaiKelasScreenState();
}

class _NilaiKelasScreenState extends State<NilaiKelasScreen> {
  late Future<List<_Rekap>> _data = _ambil();

  Future<List<_Rekap>> _ambil() async {
    final data = await Supabase.instance.client
        .rpc('nilai_kelas', params: {'p_kelas_id': widget.kelas.id});
    final peta = <String, _Rekap>{};
    for (final r in (data as List)) {
      final m = r as Map<String, dynamic>;
      final id = m['user_id'] as String;
      final rekap = peta.putIfAbsent(
        id,
        () => _Rekap((m['nama'] as String?) ?? '(tanpa nama)'),
      );
      if (m['benar'] != null && m['total'] != null) {
        rekap.percobaan.add(_Percobaan(
          benar: (m['benar'] as num).toInt(),
          total: (m['total'] as num).toInt(),
          waktu: m['created_at'] == null
              ? null
              : DateTime.tryParse(m['created_at'] as String)?.toLocal(),
        ));
      }
    }
    return peta.values.toList();
  }

  void _muatUlang() {
    setState(() => _data = _ambil());
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), duration: const Duration(seconds: 8)),
    );
  }

  static String _tgl(DateTime? w) {
    if (w == null) return '';
    String d2(int n) => n.toString().padLeft(2, '0');
    return '${d2(w.day)}/${d2(w.month)}/${w.year} ${d2(w.hour)}:${d2(w.minute)}';
  }

  static String _esc(String s) => '"${s.replaceAll('"', '""')}"';

  String _buatCsv(List<_Rekap> data) {
    final b = StringBuffer();
    b.writeln('Nama,Percobaan ke,Benar,Total,Skor,Waktu');
    for (final r in data) {
      if (r.percobaan.isEmpty) {
        b.writeln('${_esc(r.nama)},,,,,');
        continue;
      }
      for (var i = 0; i < r.percobaan.length; i++) {
        final p = r.percobaan[i];
        b.writeln([
          _esc(r.nama),
          i + 1,
          p.benar,
          p.total,
          p.skor.round(),
          _esc(_tgl(p.waktu)),
        ].join(','));
      }
    }
    return b.toString();
  }

  Future<void> _ekspor(List<_Rekap> data) async {
    final csv = _buatCsv(data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nilai: ${widget.kelas.nama}')),
      body: FutureBuilder<List<_Rekap>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _muatUlang);
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada siswa di kelas ini. Bagikan kode kelas ke siswa.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${data.length} siswa • Kode ${widget.kelas.kode}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _ekspor(data),
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
                    final r = data[i];
                    return Card(
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          r.nama,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          r.percobaan.isEmpty
                              ? 'Belum mengerjakan kuis'
                              : '${r.percobaan.length} percobaan • rata-rata ${r.rataRata.round()}',
                        ),
                        children: [
                          for (var j = 0; j < r.percobaan.length; j++)
                            ListTile(
                              dense: true,
                              title: Text(
                                'Percobaan ${j + 1}: '
                                '${r.percobaan[j].benar}/${r.percobaan[j].total} benar '
                                '(skor ${r.percobaan[j].skor.round()})',
                              ),
                              subtitle: Text(_tgl(r.percobaan[j].waktu)),
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