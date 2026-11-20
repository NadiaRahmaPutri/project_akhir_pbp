import 'package:flutter/material.dart';
import '../models/soal.dart';
import '../services/kelola_service.dart';

/// Form tambah soal (soal == null) atau ubah soal. Empat pilihan, satu benar.
class SoalFormScreen extends StatefulWidget {
  final Soal? soal;

  const SoalFormScreen({super.key, this.soal});

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
  late int _benar = _awalBenar();
  bool _menyimpan = false;

  bool get _edit => widget.soal != null;

  int _awalBenar() {
    final b = widget.soal?.jawabanBenar ?? 0;
    return (b >= 0 && b <= 3) ? b : 0;
  }

  @override
  void dispose() {
    _pertanyaanC.dispose();
    for (final c in _pilihanC) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);

    final pertanyaan = _pertanyaanC.text.trim();
    final pilihan = _pilihanC.map((c) => c.text.trim()).toList();

    try {
      if (_edit) {
        await KelolaService.ubahSoal(widget.soal!.id, pertanyaan, pilihan, _benar);
      } else {
        await KelolaService.tambahSoal(pertanyaan, pilihan, _benar);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan. Periksa koneksi internet.')),
      );
      setState(() => _menyimpan = false);
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
            const SizedBox(height: 12),
            for (var i = 0; i < 4; i++) ...[
              TextFormField(
                controller: _pilihanC[i],
                decoration: InputDecoration(
                  labelText: 'Pilihan ${_huruf[i]}',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Pilihan ${_huruf[i]} wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            const Text('Jawaban yang benar'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('A')),
                ButtonSegment(value: 1, label: Text('B')),
                ButtonSegment(value: 2, label: Text('C')),
                ButtonSegment(value: 3, label: Text('D')),
              ],
              selected: {_benar},
              onSelectionChanged: (s) => setState(() => _benar = s.first),
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
