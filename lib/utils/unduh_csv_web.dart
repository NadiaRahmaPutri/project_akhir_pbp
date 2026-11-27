import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Versi web (Chrome): mengunduh file CSV langsung.
Future<bool> unduhCsv(String namaFile, String isi) async {
  final bytes = Uint8List.fromList(utf8.encode('\uFEFF$isi'));
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement;
  a.href = url;
  a.download = namaFile;
  a.click();
  web.URL.revokeObjectURL(url);
  return true;
}