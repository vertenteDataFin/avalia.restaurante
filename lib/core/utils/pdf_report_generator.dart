import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pdf_downloader/pdf_downloader.dart';
import 'report_generator.dart';

class PdfReportGenerator {
  /// Gera o documento PDF profissional com tipografia legível, paginação automática e layout sem estouro
  static Future<Uint8List> generateSinglePagePdf(ExecutiveReportData report) async {
    final pdf = pw.Document();
    final df = DateFormat('dd/MM/yyyy HH:mm');

    // Paleta de Cores Corporativas
    const primaryGreen = PdfColor.fromInt(0xFF005A2B);
    const lightGreenBg = PdfColor.fromInt(0xFFE8F5E9);
    const darkBlue = PdfColor.fromInt(0xFF0277BD);
    const lightBlueBg = PdfColor.fromInt(0xFFE1F5FE);
    const darkAmber = PdfColor.fromInt(0xFFE65100);
    const lightAmberBg = PdfColor.fromInt(0xFFFFF8E1);
    const darkRed = PdfColor.fromInt(0xFFC62828);
    const lightRedBg = PdfColor.fromInt(0xFFFFEBEE);
    const textDark = PdfColor.fromInt(0xFF212121);
    const textMuted = PdfColor.fromInt(0xFF555555);
    const borderColor = PdfColor.fromInt(0xFFCFD8DC);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Avalia Restaurante | Relatorio Gerencial de Qualidade',
                  style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
                pw.Text(
                  'Pagina ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // ==========================================
          // CABEÇALHO DO DOCUMENTO
          // ==========================================
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: primaryGreen,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RELATORIO EXECUTIVO DE QUALIDADE DAS REFEICOES',
                        style: pw.TextStyle(
                          fontSize: 12.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Periodo: ${report.periodLabel}  |  Unidade: ${report.unitFilter}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Painel Gerencial',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Gerado em: ${df.format(report.generatedAt)}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // ==========================================
          // 1. INDICADORES PRINCIPAIS DE DESEMPENHO (KPIS)
          // ==========================================
          _buildSectionHeader('1. Indicadores Principais de Desempenho (KPIs)', primaryGreen),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _buildKpiBox(
                'Taxa de Satisfacao',
                '${report.satisfactionRate.toStringAsFixed(1)}%',
                '${report.muitoBoaCount + report.boaCount} de ${report.totalFeedbacks} avaliacoes',
                report.satisfactionRate >= 80 ? primaryGreen : (report.satisfactionRate >= 65 ? darkAmber : darkRed),
                report.satisfactionRate >= 80 ? lightGreenBg : (report.satisfactionRate >= 65 ? lightAmberBg : lightRedBg),
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                'Tendencia Temporal',
                report.trendLabelClean,
                report.trendDirection == TrendDirection.improving
                    ? 'Curva ascendente'
                    : (report.trendDirection == TrendDirection.declining ? 'Alerta de queda' : 'Nivel estavel'),
                report.trendDirection == TrendDirection.improving ? primaryGreen : (report.trendDirection == TrendDirection.declining ? darkRed : textDark),
                report.trendDirection == TrendDirection.improving ? lightGreenBg : (report.trendDirection == TrendDirection.declining ? lightRedBg : PdfColors.grey200),
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                'Indice Excelencia',
                '${report.excellenceRate.toStringAsFixed(1)}%',
                '${report.muitoBoaCount} votos "Muito Boa"',
                primaryGreen,
                lightGreenBg,
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                'Desaprovacao',
                '${report.disapprovalRate.toStringAsFixed(1)}%',
                '${report.muitoRuimCount} votos "Muito Ruim"',
                report.disapprovalRate > 15 ? darkRed : textDark,
                report.disapprovalRate > 15 ? lightRedBg : PdfColors.grey200,
              ),
            ],
          ),

          pw.SizedBox(height: 6),

          // Faixa Diagnóstica da Tendência
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: report.trendDirection == TrendDirection.improving
                  ? lightGreenBg
                  : (report.trendDirection == TrendDirection.declining ? lightRedBg : lightBlueBg),
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(
                color: report.trendDirection == TrendDirection.improving
                    ? primaryGreen
                    : (report.trendDirection == TrendDirection.declining ? darkRed : darkBlue),
                width: 0.6,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Diagnostico da Tendencia: ${report.trendSummary}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: report.trendDirection == TrendDirection.improving
                          ? primaryGreen
                          : (report.trendDirection == TrendDirection.declining ? darkRed : darkBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ==========================================
          // 2. COMPARATIVO DIRETO POR UNIDADE
          // ==========================================
          _buildSectionHeader('2. Comparativo Direto por Unidade', primaryGreen),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildUnitBox(report.pedraStats, primaryGreen, lightGreenBg),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildUnitBox(report.vertenteStats, darkBlue, lightBlueBg),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // ==========================================
          // 3. MINERAÇÃO DE TÓPICOS NOS COMENTÁRIOS
          // ==========================================
          _buildSectionHeader('3. Mineracao de Topicos nos Comentarios (${report.totalComments} com comentarios)', primaryGreen),
          pw.SizedBox(height: 6),

          if (report.criticalTopics.isEmpty && report.positiveTopics.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: borderColor, width: 0.6),
              ),
              child: pw.Text(
                'Nenhum comentario textual especifico registrado no periodo filtrado.',
                style: const pw.TextStyle(fontSize: 9, color: textMuted),
              ),
            )
          else
            pw.Column(
              children: [
                ...report.criticalTopics.take(3).map((topic) => _buildTopicCard(topic, isCritical: true)),
                ...report.positiveTopics.take(1).map((topic) => _buildTopicCard(topic, isCritical: false)),
              ],
            ),

          pw.SizedBox(height: 12),

          // ==========================================
          // 4. SÍNTESE DO DIAGNÓSTICO & 5. PLANO DE AÇÃO
          // ==========================================
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Coluna Esquerda: Diagnóstico
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: lightAmberBg,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: darkAmber, width: 0.6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '4. Sintese do Diagnostico Executivo',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      ...report.improvementPoints.take(3).map(
                            (point) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 5),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Container(
                                    width: 3.5,
                                    height: 3.5,
                                    margin: const pw.EdgeInsets.only(top: 4, right: 6),
                                    decoration: const pw.BoxDecoration(
                                      shape: pw.BoxShape.circle,
                                      color: darkAmber,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      point,
                                      style: const pw.TextStyle(fontSize: 9, color: textDark, lineSpacing: 1.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              // Coluna Direita: Plano de Ação
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: lightGreenBg,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: primaryGreen, width: 0.6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '5. Plano de Acao (Cozinha & Operacao)',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      ...report.actionableRecommendations.take(3).toList().asMap().entries.map(
                            (entry) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 5),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '${entry.key + 1}. ',
                                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryGreen),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      entry.value,
                                      style: const pw.TextStyle(fontSize: 9, color: textDark, lineSpacing: 1.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 10.5,
        fontWeight: pw.FontWeight.bold,
        color: color,
      ),
    );
  }

  static pw.Widget _buildKpiBox(
    String title,
    String value,
    String subtitle,
    PdfColor color,
    PdfColor bg,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(5),
          border: pw.Border.all(color: color, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF424242)),
              maxLines: 1,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF616161)),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildUnitBox(UnitStats stats, PdfColor color, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: color, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Unidade ${stats.unitName}',
                style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: color),
              ),
              pw.Text(
                '${stats.totalFeedbacks} avaliacoes (${stats.commentCount} com texto)',
                style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF616161)),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Satisfacao: ${stats.satisfactionRate.toStringAsFixed(1)}%',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: stats.satisfactionRate >= 75 ? color : const PdfColor.fromInt(0xFFC62828),
                ),
              ),
              pw.Text(
                'Muito Boa: ${stats.muitoBoaCount} | Boa: ${stats.boaCount} | Muito Ruim: ${stats.muitoRuimCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF424242)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTopicCard(TopicInsight topic, {required bool isCritical}) {
    final color = isCritical ? const PdfColor.fromInt(0xFFC62828) : const PdfColor.fromInt(0xFF005A2B);
    final bg = isCritical ? const PdfColor.fromInt(0xFFFFF5F5) : const PdfColor.fromInt(0xFFF1F8E9);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 5),
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: color, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      '${topic.count} ${topic.count == 1 ? "mencao" : "mencoes"}',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    topic.title,
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: color),
                  ),
                ],
              ),
            ],
          ),
          if (topic.sampleSnippets.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border(left: pw.BorderSide(color: PdfColor.fromInt(0xFF90A4AE), width: 2)),
              ),
              child: pw.Text(
                '"${topic.sampleSnippets.first}"',
                style: const pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: PdfColor.fromInt(0xFF37474F)),
              ),
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Acao recomendada: ',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: color),
              ),
              pw.Expanded(
                child: pw.Text(
                  topic.recommendation,
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF424242)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Faz o download / compartilhamento direto do arquivo PDF (compatível com Web e Mobile)
  static Future<void> exportPdf(ExecutiveReportData report) async {
    final bytes = await generateSinglePagePdf(report);
    final filename = 'Relatorio_Executivo_Refeicoes_${DateFormat('yyyyMMdd_HHmm').format(report.generatedAt)}.pdf';
    await PdfDownloader.downloadBytes(bytes, filename);
  }

  /// Abre a caixa de diálogo nativa de impressão/visualização
  static Future<void> printPdf(ExecutiveReportData report) async {
    final filename = 'Relatorio_Executivo_Refeicoes_${DateFormat('yyyyMMdd_HHmm').format(report.generatedAt)}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => generateSinglePagePdf(report),
      name: filename,
    );
  }
}
