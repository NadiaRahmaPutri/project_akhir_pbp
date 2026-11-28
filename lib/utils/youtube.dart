/// Mengambil ID video dari tautan YouTube (hanya https). Hasil null bila
/// tautan bukan dari YouTube atau ID-nya tidak valid.
///
/// Dikenali: youtube.com/watch?v=ID, youtu.be/ID, youtube.com/embed/ID,
/// youtube.com/shorts/ID, youtube.com/live/ID (juga m.youtube.com).
String? idYoutube(String teks) {
  final t = teks.trim();
  if (t.isEmpty) return null;

  final uri = Uri.tryParse(t);
  if (uri == null || uri.scheme != 'https') return null;

  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www\.|m\.)'), '');
  final bagian = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  String? id;
  if (host == 'youtu.be') {
    if (bagian.isNotEmpty) id = bagian.first;
  } else if (host == 'youtube.com') {
    if (bagian.length >= 2 &&
        const {'embed', 'shorts', 'live', 'v'}.contains(bagian.first)) {
      id = bagian[1];
    } else if (bagian.isNotEmpty && bagian.first == 'watch') {
      id = uri.queryParameters['v'];
    }
  }

  if (id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) return id;
  return null;
}
