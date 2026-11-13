import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_akhir_pbp/screens/login_screen.dart';

Widget _buatApp() => const MaterialApp(home: LoginScreen());

Finder get _tombolMasuk => find.widgetWithText(FilledButton, 'Masuk');
Finder get _fieldEmail => find.widgetWithText(TextFormField, 'Email');
Finder get _fieldSandi => find.widgetWithText(TextFormField, 'Kata sandi');

void main() {
  testWidgets('Form kosong menampilkan pesan wajib diisi', (tester) async {
    await tester.pumpWidget(_buatApp());

    await tester.tap(_tombolMasuk);
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
  });

  testWidgets('Email tanpa @ ditolak', (tester) async {
    await tester.pumpWidget(_buatApp());

    await tester.enterText(_fieldEmail, 'nadiagmail.com');
    await tester.enterText(_fieldSandi, '123456');
    await tester.tap(_tombolMasuk);
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
  });

  testWidgets('Kata sandi kurang dari 6 karakter ditolak', (tester) async {
    await tester.pumpWidget(_buatApp());

    await tester.enterText(_fieldEmail, 'nadia@gmail.com');
    await tester.enterText(_fieldSandi, '12345');
    await tester.tap(_tombolMasuk);
    await tester.pump();

    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsNothing);
  });

  testWidgets('Mode daftar menampilkan kolom Nama dan memvalidasinya', (
    tester,
  ) async {
    await tester.pumpWidget(_buatApp());

    expect(find.widgetWithText(TextFormField, 'Nama'), findsNothing);

    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Nama'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
  });
}
