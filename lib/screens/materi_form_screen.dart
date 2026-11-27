import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/materi.dart';
import '../services/gambar_service.dart';
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

  String? _gambarUrl; // gambar yang sudah tersimpan
  XFile? _gambarBaru; // gambar yang baru dipilih (belum diunggah)
  Uint8List? _pratinjau; // isi gambar baru, untuk ditampilkan

  bool get _edit => widget.materi != null;
  bool get _adaGambar => _pratinjau != null || _gambarUrl != null;

  @override
  void initState() {
    super.initState();
    _gambarUrl = widget.materi?.gambarUrl;
  }

  @override
  void dispose() {
    _judulC.dispose();
    _ringkasanC.dispose();
    _isiC.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _pilihGambar() async {
    try {
      final file = await GambarService.pilihGambar();
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > GambarService.batasUkuran) {
        _pesan('Ukuran gambar maksimal 2 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _gambarBaru = file;
        _pratinjau = bytes;
      });
    } catch (_) {
      _pesan('Gagal membuka gambar.');
    }
  }

  void _hapusGambar() {
    setState(() {
      _gambarBaru = null;
      _pratinjau = null;
      _gambarUrl = null;
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);

    final judul = _judulC.text.trim();
    final ringkasan = _ringkasanC.text.trim();
    final isi = _isiC.text.trim();

    try {
      var url = _gambarUrl;
      final baru = _gambarBaru;
      if (baru != null) {
        url = await GambarService.unggah(baru);
      }

      if (_edit) {
        await KelolaService.ubahMateri(
          widget.materi!.id,
          judul,
          ringkasan,
          isi,
          gambarUrl: url,
        );
      } else {
        await KelolaService.tambahMateri(judul, ringkasan, isi, gambarUrl: url);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _pesan('Gagal menyimpan. Periksa koneksi internet dan ukuran gambar.');
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  Widget _bagianGambar() {
    final Widget isi;
    if (_pratinjau != null) {
      isi = Image.memory(_pratinjau!, fit: BoxFit.cover);
    } else if (_gambarUrl != null) {
      isi = Image.network(
        _gambarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            const Center(child: Text('Gambar tidak bisa dimuat')),
      );
    } else {
      isi = const Center(child: Icon(Icons.image_outlined, size: 48));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Gambar pendukung (opsional)'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: const Color(0xFFE3EEFF), child: isi),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _menyimpan ? null : _pilihGambar,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_adaGambar ? 'Ganti gambar' : 'Pilih gambar'),
              ),
            ),
            if (_adaGambar) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Hapus gambar',
                onPressed: _menyimpan ? null : _hapusGambar,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
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
            const SizedBox(height: 16),
            _bagianGambar(),
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
