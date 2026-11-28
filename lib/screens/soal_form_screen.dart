import 'package:flutter/material.dart';
import '../models/soal.dart';
import '../services/kelola_service.dart';

/// Form tambah soal (soal == null) atau ubah soal untuk sebuah kuis.
/// Empat pilihan, tiap pilihan punya bobot. Tidak ada jawaban salah:
/// nilai mahasiswa dihitung dari bobot pilihan yang dipilih.
class SoalFormScreen extends StatefulWidget {
  final int kelasId;
  final int kuisId;
  final Soal? soal;

  const SoalFormScreen({
    super.key,
    required this.kelasId,
    required this.kuisId,
    this.soal,
  });

  @override
  State<SoalFormScreen> createState() => _SoalFormScreenState();
}

class _SoalFormScreenState extends State<SoalFormScreen> {
  static const _huruf = ['A', 'B', 'C', 'D'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pertanyaanC =
      TextEditingController(text: widget.soal?.pertanyaan ?? '');
  late final List<TextEditingController> _pilihanC = List.generate(4, (i) {
    final s = widget.soal;
    final teks = (s != null && i < s.pilihan.length) ? s.pilihan[i] : '';
    return TextEditingController(text: teks);
  });
  late final List<TextEditingController> _bobotC = List.generate(4, (i) {
    final s = widget.soal;
    final nilai = (s != null && i < s.bobot.length) ? s.bobot[i] : 0;
    return TextEditingController(text: '$nilai');
  });
  late final TextEditingController _waktuC =
      TextEditingController(text: '${widget.soal?.waktuDetik ?? 30}');
  bool _menyimpan = false;

  bool get _edit => widget.soal != null;

  @override
  void dispose() {
    _pertanyaanC.dispose();
    for (final c in _pilihanC) {
      c.dispose();
    }
    for (final c in _bobotC) {
      c.dispose();
    }
    _waktuC.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), duration: const Duration(seconds: 8)),
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final pertanyaan = _pertanyaanC.text.trim();
    final pilihan = _pilihanC.map((c) => c.text.trim()).toList();
    final bobot = _bobotC.map((c) => int.parse(c.text.trim())).toList();
    final waktu = int.parse(_waktuC.text.trim());

    if (!bobot.any((b) => b > 0)) {
      _pesan('Setidaknya satu pilihan harus berbobot lebih dari 0.');
      return;
    }

    setState(() {
      _menyimpan = true;
    });
    try {
      if (_edit) {
        await KelolaService.ubahSoal(
          widget.soal!.id,
          pertanyaan,
          pilihan,
          bobot,
          waktu,
        );
      } else {
        await KelolaService.tambahSoal(
          kelasId: widget.kelasId,
          kuisId: widget.kuisId,
          pertanyaan: pertanyaan,
          pilihan: pilihan,
          bobot: bobot,
          waktuDetik: waktu,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _pesan('Gagal menyimpan. Periksa koneksi internet.');
      setState(() {
        _menyimpan = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Ubah soal' : 'Tambah soal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _pertanyaanC,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Pertanyaan',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Pertanyaan wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilihan dan bobot. Tidak ada jawaban salah: nilai ditentukan '
              'oleh bobot (0 sampai 100) pilihan yang dipilih mahasiswa.',
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 4; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pilihanC[i],
                      decoration: InputDecoration(
                        labelText: 'Pilihan ${_huruf[i]}',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pilihan ${_huruf[i]} wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      controller: _bobotC[i],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bobot',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final angka = int.tryParse((v ?? '').trim());
                        if (angka == null) return 'Angka';
                        if (angka < 0 || angka > 100) return '0-100';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            TextFormField(
              controller: _waktuC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Batas waktu soal ini (detik)',
                helperText: 'Antara 10 dan 600 detik',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final angka = int.tryParse((v ?? '').trim());
                if (angka == null) return 'Isi dengan angka';
                if (angka < 10 || angka > 600) {
                  return 'Batas waktu harus 10 sampai 600 detik';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _menyimpan ? null : _simpan,
              child: _menyimpan
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
