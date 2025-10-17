import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/calculations.dart';

void main() {
  group('estimateOneRm', () {
    test('Epley: 10 reps @ 100kg = ~133.3kg', () {
      final oneRm = estimateOneRm(
        reps: 10,
        weight: 100.0,
        formula: OneRmFormula.epley,
      );
      expect(oneRm, closeTo(133.3, 0.5));
    });

    test('1 rep retorna o próprio peso', () {
      final oneRm = estimateOneRm(reps: 1, weight: 100.0);
      expect(oneRm, equals(100.0));
    });

    test('Valores inválidos retornam 0', () {
      expect(estimateOneRm(reps: 0, weight: 100), equals(0.0));
      expect(estimateOneRm(reps: 10, weight: -5), equals(0.0));
    });

    test('Brzycki funciona', () {
      final oneRm = estimateOneRm(
        reps: 5,
        weight: 100.0,
        formula: OneRmFormula.brzycki,
      );
      expect(oneRm, greaterThan(100.0));
    });

    test('Wathan funciona', () {
      final oneRm = estimateOneRm(
        reps: 8,
        weight: 100.0,
        formula: OneRmFormula.wathan,
      );
      expect(oneRm, greaterThan(100.0));
    });
  });

  group('Helpers', () {
    test('percentageOf1RM calcula corretamente', () {
      final pct = percentageOf1RM(weight: 80, oneRM: 100);
      expect(pct, equals(0.8));
    });

    test('weightForPercentage calcula corretamente', () {
      final weight = weightForPercentage(oneRM: 100, percentage: 0.85);
      expect(weight, equals(85.0));
    });

    test('getFormulaDescription retorna descrição', () {
      final desc = getFormulaDescription(OneRmFormula.epley);
      expect(desc, contains('Epley'));
    });
  });

  group('Extensão SetEntryOneRm', () {
    test('Calcula 1RM a partir de record', () {
      final set = (reps: 8, weight: 100.0);
      expect(set.oneRm, greaterThan(100.0));
    });

    test('oneRmWith permite escolher fórmula', () {
      final set = (reps: 8, weight: 100.0);
      final epley = set.oneRmWith(OneRmFormula.epley);
      final brzycki = set.oneRmWith(OneRmFormula.brzycki);
      
      expect(epley, isNot(equals(brzycki)));
    });
  });
}