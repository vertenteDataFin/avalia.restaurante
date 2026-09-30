import 'package:flutter_test/flutter_test.dart';
import 'package:app_mob_alimento/core/utils/report_generator.dart';
import 'package:app_mob_alimento/core/utils/pdf_report_generator.dart';
import 'package:app_mob_alimento/data/models/feedback_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfReportGenerator Tests', () {
    test('generateSinglePagePdf generates non-empty PDF bytes for empty report', () async {
      final report = ReportGenerator.generate(
        feedbacks: [],
        periodLabel: 'Todo o Período',
        unitFilter: 'Todas',
      );

      final pdfBytes = await PdfReportGenerator.generateSinglePagePdf(report);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });

    test('generateSinglePagePdf generates valid PDF bytes with full data', () async {
      final now = DateTime.now();
      final feedbacks = [
        FeedbackItem(
          id: '1',
          unit: 'Pedra',
          foodRating: 'Muito ruim',
          type: 'Reclamação',
          message: 'A comida estava fria e o feijão sem sal.',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        FeedbackItem(
          id: '2',
          unit: 'Vertente',
          foodRating: 'Muito Boa',
          type: 'Elogio',
          message: 'Excelente refeição, muito saborosa e atendimento rápido!',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final report = ReportGenerator.generate(
        feedbacks: feedbacks,
        periodLabel: 'Últimos 7 dias',
        unitFilter: 'Todas',
      );

      final pdfBytes = await PdfReportGenerator.generateSinglePagePdf(report);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(500));
    });
  });
}
