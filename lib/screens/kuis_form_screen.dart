import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kelas_service.dart';
import '../services/kuis_service.dart';
import '../utils/format_waktu.dart';

/// Dosen: membuat atau mengubah satu kuis (judul, jadwal buka-tutup, acak).
class KuisFormScreen extends StatefulWidget {
  final Kelas kelas;
  final Kuis? kuis;

  const KuisFormScreen({super.key, required this.kelas, this.kuis});

  @override
  State<KuisFormScreen> createState() => _KuisFormScreenState();
}

class _KuisFormScreenState extends State<KuisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulC =
      TextEditingController(text: widget.kuis?.judul ?? '');
  late DateTime _buka = widget.kuis?.bukaPada ?? _awalBuka();
  late DateTime _tutup =
      widget.kuis?.tutupPada ?? _buka.add(const Duration(days: 7));
  late bool _acak = widget.kuis?.acak ?? true;
  bool _menyimpan = false;

  bool get _edit => widget.kuis != null;

  static DateTime _awalBuka() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, n.hour + 1);
  }

  @override
  void dispose() {
    _judulC.dispose();
    super.dispose();
  }

  Future<DateTime?> _pilih(DateTime awal) async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: awal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (tgl == null || !mounted) return null;
    final jam = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(awal),
    );
    if (jam == null) return null;
    return DateTime(tgl.year, tgl.month, tgl.day, jam.hour, jam.minute);
  }

  Future<void> _ubahBuka() async {
    final w = await _pilih(_buka);
    if (w == null) return;
    setState(() {
      _buka = w;
    });
  }

  Future<void> _ubahTutup() async {
    final w = await _pilih(_tutup);
    if (w == null) return;
    setState(() {
      _tutup = w;
    });
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), duration: const Duration(seconds: 8)),
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_tutup.isAfter(_buka)) {
      _pesan('Waktu tutup harus setelah waktu buka.');
      return;
    }
    setState(() {
      _menyimpan = true;
    });
    final judul = _judulC.text.trim();
    try {
      if (_edit) {
        await KuisService.ubahKuis(
            widget.kuis!.id, judul, _buka, _tutup, _acak);
      } else {
        await KuisService.buatKuis(
            widget.kelas.id, judul, _buka, _tutup, _acak);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _pesan('Gagal menyimpan: ${e.message}');
      setState(() {
        _menyimpan = false;
      });
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
      appBar: AppBar(title: Text(_edit ? 'Ubah kuis' : 'Buat kuis')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judulC,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Judul kuis',
                hintText: 'Contoh: Kuis Minggu 1',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Judul wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Dibuka pada'),
                    subtitle: Text(tglJam(_buka)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _ubahBuka,
                  ),
                  ListTile(
                    leading: const Icon(Icons.stop_circle_outlined),
                    title: const Text('Ditutup pada'),
                    subtitle: Text(tglJam(_tutup)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _ubahTutup,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Acak soal dan pilihan jawaban'),
              subtitle: const Text('Urutan berbeda untuk tiap mahasiswa'),
              value: _acak,
              onChanged: (v) {
                setState(() {
                  _acak = v;
                });
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Mahasiswa hanya bisa mengerjakan kuis satu kali, dan hanya '
              'selama kuis dibuka. Dosen dapat mereset di halaman Nilai '
              'mahasiswa bila ada kendala.',
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
