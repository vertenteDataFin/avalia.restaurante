import 'package:flutter_test/flutter_test.dart';
import 'package:app_mob_alimento/core/utils/report_generator.dart';
import 'package:app_mob_alimento/data/models/feedback_item.dart';

void main() {
  group('ReportGenerator Tests', () {
    test('generate empty report handles gracefully', () {
      final report = ReportGenerator.generate(
        feedbacks: [],
        periodLabel: 'Todo o Período',
        unitFilter: 'Todas',
      );

      expect(report.totalFeedbacks, equals(0));
      expect(report.satisfactionRate, equals(0.0));
      expect(report.criticalTopics, isEmpty);
      expect(report.improvementPoints.isNotEmpty, isTrue);
      expect(report.toPlainText().contains('RESUMO GERAL'), isTrue);
    });

    test('calculates satisfaction, unit stats, topics, and trend correctly', () {
      final now = DateTime.now();
      final feedbacks = [
        // 1ª metade (mais antigos)
        FeedbackItem(
          id: '1',
          unit: 'Pedra',
          foodRating: 'Muito ruim',
          type: 'Reclamação',
          message: 'A comida estava muito fria e sem sal nenhum.',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
        FeedbackItem(
          id: '2',
          unit: 'Pedra',
          foodRating: 'Boa',
          type: 'Sugestão',
          message: 'Poderia ter mais variedade de saladas e frutas.',
          createdAt: now.subtract(const Duration(days: 8)),
        ),
        // 2ª metade (mais recentes, com melhoria)
        FeedbackItem(
          id: '3',
          unit: 'Vertente',
          foodRating: 'Muito Boa',
          type: 'Elogio',
          message: 'Parabéns equipe, o tempero estava perfeito e comida quentinha!',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        FeedbackItem(
          id: '4',
          unit: 'Vertente',
          foodRating: 'Muito Boa',
          type: 'Elogio',
          message: 'Excelente refeição, muito saboroso.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final report = ReportGenerator.generate(
        feedbacks: feedbacks,
        periodLabel: 'Últimos 30 dias',
        unitFilter: 'Todas',
      );

      expect(report.totalFeedbacks, equals(4));
      expect(report.muitoBoaCount, equals(2));
      expect(report.boaCount, equals(1));
      expect(report.muitoRuimCount, equals(1));
      expect(report.satisfactionRate, equals(75.0)); // (2 + 1) / 4 * 100
      expect(report.excellenceRate, equals(50.0)); // 2 / 4 * 100
      expect(report.disapprovalRate, equals(25.0)); // 1 / 4 * 100

      // Pedra vs Vertente
      expect(report.pedraStats.totalFeedbacks, equals(2));
      expect(report.pedraStats.satisfactionRate, equals(50.0));
      expect(report.vertenteStats.totalFeedbacks, equals(2));
      expect(report.vertenteStats.satisfactionRate, equals(100.0));

      // Trend
      expect(report.trendDirection, equals(TrendDirection.improving));
      expect(report.trendDeltaPercent, greaterThan(0));

      // Topics
      final criticalTitles = report.criticalTopics.map((t) => t.title).toList();
      expect(criticalTitles.contains('Tempero e Teor de Sal'), isTrue);
      expect(criticalTitles.contains('Temperatura e Ponto de Cocção'), isTrue);
      expect(criticalTitles.contains('Variedade do Cardápio e Saladas'), isTrue);

      final positiveTitles = report.positiveTopics.map((t) => t.title).toList();
      expect(positiveTitles.contains('Aprovação de Sabor e Qualidade'), isTrue);

      // Plaintext export
      final text = report.toPlainText();
      expect(text.contains('RELATÓRIO EXECUTIVO'), isTrue);
      expect(text.contains('Unidade Pedra'), isTrue);
      expect(text.contains('Unidade Vertente'), isTrue);
      expect(text.contains('PLANO DE AÇÃO RECOMENDADO'), isTrue);
    });
  });
}
