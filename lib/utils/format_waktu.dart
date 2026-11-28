String _d2(int n) => n.toString().padLeft(2, '0');

/// Contoh: 28/11/2026 20:11
String tglJam(DateTime w) =>
    '${_d2(w.day)}/${_d2(w.month)}/${w.year} ${_d2(w.hour)}:${_d2(w.minute)}';

String jadwalKuis(DateTime buka, DateTime tutup) =>
    '${tglJam(buka)} – ${tglJam(tutup)}';
