import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget wrapper para testes que precisam de Riverpod
Widget createTestWidget(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// Encontrar widget por tipo
Finder findWidgetByType<T>() {
  return find.byType(T);
}

/// Verificar se widget existe
void expectWidgetExists(Finder finder) {
  expect(finder, findsOneWidget);
}

/// Verificar se widget não existe
void expectWidgetNotExists(Finder finder) {
  expect(finder, findsNothing);
}

/// Aguardar animações finalizarem
Future<void> pumpAndWait(WidgetTester tester, [Duration? duration]) async {
  await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 100));
}