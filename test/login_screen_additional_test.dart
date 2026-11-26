import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_akhir_pbp/screens/login_screen.dart';

void main() {
  Future<void> bukaHalaman(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  }

  testWidgets('menampilkan form Masuk', (tester) async {
    await bukaHalaman(tester);

    expect(find.text('Masuk ke akunmu'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata sandi'), findsOneWidget);
    expect(find.text('Belum punya akun? Daftar'), findsOneWidget);
  });

  testWidgets('form kosong menampilkan pesan validasi', (tester) async {
    await bukaHalaman(tester);

    await tester.tap(find.text('Masuk').last);
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
  });

  testWidgets('email tanpa @ ditolak', (tester) async {
    await bukaHalaman(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'nadia');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Masuk').last);
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
  });

  testWidgets('kata sandi kurang dari 6 karakter ditolak', (tester) async {
    await bukaHalaman(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Masuk').last);
    await tester.pump();

    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
  });

  testWidgets('mode Daftar menampilkan kolom Nama dan memvalidasinya', (
    tester,
  ) async {
    await bukaHalaman(tester);

    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pump();

    expect(find.text('Buat akun baru'), findsOneWidget);
    expect(find.text('Nama'), findsOneWidget);

    await tester.tap(find.text('Daftar').last);
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
  });
}
