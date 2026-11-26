import 'package:flutter/material.dart';
import '../models/materi.dart';
import '../services/kelola_service.dart';

/// Form tambah materi (materi == null) atau ubah materi.
class MateriFormScreen extends StatefulWidget {
  final Materi? materi;

  const MateriFormScreen({super.key, this.materi});

  @override
  State<MateriFormScreen> createState() => _MateriFormScreenState();
}

class _MateriFormScreenState extends State<MateriFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulC =
      TextEditingController(text: widget.materi?.judul ?? '');
  late final TextEditingController _ringkasanC =
      TextEditingController(text: widget.materi?.ringkasan ?? '');
  late final TextEditingController _isiC =
      TextEditingController(text: widget.materi?.isi ?? '');
  bool _menyimpan = false;

  bool get _edit => widget.materi != null;

  @override
  void dispose() {
    _judulC.dispose();
    _ringkasanC.dispose();
    _isiC.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);

    final judul = _judulC.text.trim();
    final ringkasan = _ringkasanC.text.trim();
    final isi = _isiC.text.trim();

    try {
      if (_edit) {
        await KelolaService.ubahMateri(widget.materi!.id, judul, ringkasan, isi);
      } else {
        await KelolaService.tambahMateri(judul, ringkasan, isi);
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
      appBar: AppBar(title: Text(_edit ? 'Ubah materi' : 'Tambah materi')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judulC,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ringkasanC,
              decoration: const InputDecoration(
                labelText: 'Ringkasan (singkat)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isiC,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Isi materi',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Isi materi wajib diisi'
                  : null,
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
