import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/soal.dart';
import '../services/kuis_service.dart';
import '../utils/format_waktu.dart';

/// Satu soal yang sudah diacak: urutan[i] = indeks pilihan asli yang
/// ditampilkan di posisi ke-i.
class _Butir {
  final Soal soal;
  final List<int> urutan;

  const _Butir(this.soal, this.urutan);
}

/// Mahasiswa: halaman satu kuis. Menampilkan info dan tombol Mulai; setelah
/// dikerjakan hanya menampilkan nilai dan waktu pengerjaan.
class KuisScreen extends StatefulWidget {
  final KuisMahasiswa kuis;

  const KuisScreen({super.key, required this.kuis});

  @override
  State<KuisScreen> createState() => _KuisScreenState();
}

class _KuisScreenState extends State<KuisScreen> {
  late KuisMahasiswa _kuis = widget.kuis;

  bool _memulai = false;

  // Keadaan saat mengerjakan (_butir != null berarti sedang mengerjakan).
  List<_Butir>? _butir;
  int _indeks = 0;
  int _sisaDetik = 0;
  Timer? _timer;
  List<int?> _jawaban = [];
  bool _mengirim = false;
  bool _gagalKirim = false;
  String _pesanGagal = '';

  bool get _soalTerakhir => _indeks == (_butir?.length ?? 1) - 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), duration: const Duration(seconds: 6)),
    );
  }

  // ---------- Mulai ----------
  Future<void> _mulai() async {
    setState(() {
      _memulai = true;
    });
    var sudahMulai = false;
    try {
      await KuisService.mulaiKuis(_kuis.kuisId);
      sudahMulai = true;
      final soal = await KuisService.fetchSoalKuis(_kuis.kuisId);
      if (!mounted) return;
      if (soal.isEmpty) {
        throw StateError('Kuis ini belum punya soal');
      }

      final acak = Random();
      final daftar = List<Soal>.of(soal);
      if (_kuis.acak) daftar.shuffle(acak);
      final butir = daftar.map((s) {
        final urutan = List<int>.generate(s.pilihan.length, (i) => i);
        if (_kuis.acak) urutan.shuffle(acak);
        return _Butir(s, urutan);
      }).toList();

      setState(() {
        _butir = butir;
        _indeks = 0;
        _jawaban = List<int?>.filled(butir.length, null);
        _memulai = false;
      });
      _mulaiTimer();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _memulai = false;
      });
      _pesan(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memulai = false;
      });
      _pesan(sudahMulai
          ? 'Kuis sudah dimulai tetapi soal gagal dimuat. Hubungi dosen untuk reset.'
          : 'Gagal memulai kuis. Periksa koneksi internet.');
    }
  }

  // ---------- Timer per soal ----------
  void _mulaiTimer() {
    _timer?.cancel();
    _sisaDetik = _butir![_indeks].soal.waktuDetik;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _mengirim) return;
      if (_sisaDetik <= 1) {
        _timer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              _soalTerakhir
                  ? 'Waktu habis. Kuis diselesaikan.'
                  : 'Waktu habis. Lanjut ke soal berikutnya.',
            ),
          ),
        );
        _lanjut();
      } else {
        setState(() {
          _sisaDetik--;
        });
      }
    });
  }

  String get _waktuTeks {
    final menit = (_sisaDetik ~/ 60).toString().padLeft(2, '0');
    final detik = (_sisaDetik % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  Future<void> _lanjut() async {
    if (_mengirim) return;
    _timer?.cancel();
    if (!_soalTerakhir) {
      setState(() {
        _indeks++;
      });
      _mulaiTimer();
      return;
    }
    await _kirim();
  }

  // ---------- Kirim jawaban (nilai dihitung di server) ----------
  Future<void> _kirim() async {
    _timer?.cancel();
    setState(() {
      _mengirim = true;
      _gagalKirim = false;
    });
    final butir = _butir!;
    final jawaban = <Map<String, dynamic>>[
      for (var i = 0; i < butir.length; i++)
        {'soal_id': butir[i].soal.id, 'indeks': _jawaban[i]},
    ];

    try {
      final hasil = await KuisService.selesaiKuis(_kuis.kuisId, jawaban);
      if (!mounted) return;
      setState(() {
        _kuis = _kuis.denganHasil(hasil);
        _butir = null;
        _mengirim = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _mengirim = false;
        _gagalKirim = true;
        _pesanGagal = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mengirim = false;
        _gagalKirim = true;
        _pesanGagal = 'Jawaban belum terkirim. Periksa koneksi internet.';
      });
    }
  }

  Future<void> _konfirmasiAkhiri() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Akhiri kuis sekarang?'),
        content: const Text(
          'Jawabanmu dikirim dan soal yang belum dijawab dianggap kosong. '
          'Kesempatan mengerjakan tidak bisa diulang kecuali direset dosen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut mengerjakan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Akhiri dan kirim'),
          ),
        ],
      ),
    );
    if (yakin == true && mounted) await _kirim();
  }

  // ---------- Tampilan ----------
  @override
  Widget build(BuildContext context) {
    final mengerjakan = _butir != null;
    return PopScope(
      canPop: !mengerjakan,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_mengirim && !_gagalKirim) _konfirmasiAkhiri();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_kuis.judul)),
        body: mengerjakan ? _tampilKerja() : _tampilDetail(),
      ),
    );
  }

  Widget _kartu(IconData ikon, String judul, String isi) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(isi),
          ],
        ),
      ),
    );
  }

  Widget _kartuStatus() {
    final k = _kuis;
    switch (k.status) {
      case StatusKuis.selesai:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('Nilai kamu'),
                Text(
                  '${k.skor ?? 0}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text('Poin ${k.poin ?? 0} dari ${k.poinMaks ?? 0}'),
                if (k.selesaiPada != null) ...[
                  const SizedBox(height: 8),
                  Text('Dikerjakan: ${tglJam(k.selesaiPada!)}'),
                ],
              ],
            ),
          ),
        );
      case StatusKuis.belumSelesai:
        return _kartu(
          Icons.error_outline,
          'Pengerjaan belum selesai',
          'Kesempatanmu sudah terpakai tetapi jawabanmu belum tersimpan. '
              'Hubungi dosen untuk mereset kuis ini.',
        );
      case StatusKuis.belumDibuka:
        return _kartu(
          Icons.schedule,
          'Belum dibuka',
          'Kuis ini dibuka pada ${tglJam(k.bukaPada)}.',
        );
      case StatusKuis.ditutup:
        return _kartu(
          Icons.lock_outline,
          'Sudah ditutup',
          'Kuis ini ditutup pada ${tglJam(k.tutupPada)} dan tidak dikerjakan.',
        );
      case StatusKuis.dibuka:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ketentuan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Kuis hanya bisa dikerjakan satu kali.\n'
                  '• Kesempatan langsung terpakai saat kamu menekan Mulai.\n'
                  '• Setiap soal punya batas waktu; jika habis, soal '
                  'dilewati.\n'
                  '• Dosen bisa mereset bila ada kendala.',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        (_memulai || k.jumlahSoal == 0) ? null : _mulai,
                    child: _memulai
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(k.jumlahSoal == 0
                            ? 'Belum ada soal'
                            : 'Mulai kuis'),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _tampilDetail() {
    final k = _kuis;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(k.judul, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Jadwal: ${jadwalKuis(k.bukaPada, k.tutupPada)}'),
        const SizedBox(height: 4),
        Text(
          '${k.jumlahSoal} soal • sekitar ${(k.totalWaktu / 60).ceil()} menit',
        ),
        const SizedBox(height: 16),
        _kartuStatus(),
      ],
    );
  }

  Widget _tampilKerja() {
    if (_mengirim) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Mengirim jawaban...'),
          ],
        ),
      );
    }
    if (_gagalKirim) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 12),
              Text(_pesanGagal, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _kirim,
                child: const Text('Coba kirim lagi'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      );
    }

    final butir = _butir![_indeks];
    final soal = butir.soal;
    final skema = Theme.of(context).colorScheme;
    final genting = _sisaDetik <= soal.waktuDetik * 0.3;
    final warnaWaktu = genting ? skema.error : skema.primary;
    final latarWaktu =
        genting ? const Color(0xFFFDE8E8) : const Color(0xFFE3EEFF);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: (_indeks + 1) / _butir!.length),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Soal ${_indeks + 1} dari ${_butir!.length}'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: latarWaktu,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: warnaWaktu),
                    const SizedBox(width: 4),
                    Text(
                      _waktuTeks,
                      style: TextStyle(
                        color: warnaWaktu,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(soal.pertanyaan, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: butir.urutan.length,
              itemBuilder: (context, i) {
                final asli = butir.urutan[i];
                final dipilih = _jawaban[_indeks] == asli;
                return Card(
                  child: ListTile(
                    title: Text(soal.pilihan[asli]),
                    selected: dipilih,
                    trailing: dipilih ? const Icon(Icons.check_circle) : null,
                    onTap: () {
                      setState(() {
                        _jawaban[_indeks] = asli;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _jawaban[_indeks] == null ? null : _lanjut,
              child: Text(_soalTerakhir ? 'Selesai' : 'Lanjut'),
            ),
          ),
        ],
      ),
    );
  }
}
