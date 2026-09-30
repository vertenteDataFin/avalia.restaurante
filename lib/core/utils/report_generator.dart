import 'package:intl/intl.dart';
import '../../data/models/feedback_item.dart';

enum TrendDirection {
  improving,
  stable,
  declining,
}

class TopicInsight {
  final String title;
  final String category; // 'Atenção' ou 'Destaque Positivo'
  final int count;
  final List<String> sampleSnippets;
  final String recommendation;

  TopicInsight({
    required this.title,
    required this.category,
    required this.count,
    required this.sampleSnippets,
    required this.recommendation,
  });
}

class UnitStats {
  final String unitName;
  final int totalFeedbacks;
  final int muitoBoaCount;
  final int boaCount;
  final int muitoRuimCount;
  final int commentCount;
  final double satisfactionRate; // (Muito Boa + Boa) / Total * 100
  final double excellenceRate; // Muito Boa / Total * 100

  UnitStats({
    required this.unitName,
    required this.totalFeedbacks,
    required this.muitoBoaCount,
    required this.boaCount,
    required this.muitoRuimCount,
    required this.commentCount,
    required this.satisfactionRate,
    required this.excellenceRate,
  });
}

class ExecutiveReportData {
  final DateTime generatedAt;
  final String periodLabel;
  final String unitFilter;
  final int totalFeedbacks;
  final int totalComments;
  final int totalPhotos;

  final int muitoBoaCount;
  final int boaCount;
  final int muitoRuimCount;

  final double satisfactionRate; // (Muito Boa + Boa) / Total * 100
  final double excellenceRate; // Muito Boa / Total * 100
  final double disapprovalRate; // Muito Ruim / Total * 100

  final TrendDirection trendDirection;
  final double trendDeltaPercent; // Variação na taxa de satisfação entre a 1ª e a 2ª metade do período
  final String trendSummary;

  final UnitStats pedraStats;
  final UnitStats vertenteStats;

  final List<TopicInsight> criticalTopics;
  final List<TopicInsight> positiveTopics;
  final List<String> improvementPoints;
  final List<String> actionableRecommendations;

  ExecutiveReportData({
    required this.generatedAt,
    required this.periodLabel,
    required this.unitFilter,
    required this.totalFeedbacks,
    required this.totalComments,
    required this.totalPhotos,
    required this.muitoBoaCount,
    required this.boaCount,
    required this.muitoRuimCount,
    required this.satisfactionRate,
    required this.excellenceRate,
    required this.disapprovalRate,
    required this.trendDirection,
    required this.trendDeltaPercent,
    required this.trendSummary,
    required this.pedraStats,
    required this.vertenteStats,
    required this.criticalTopics,
    required this.positiveTopics,
    required this.improvementPoints,
    required this.actionableRecommendations,
  });

  String get trendLabel {
    switch (trendDirection) {
      case TrendDirection.improving:
        return 'Em Alta (+${trendDeltaPercent.toStringAsFixed(1)}%) 📈';
      case TrendDirection.declining:
        return 'Em Queda (${trendDeltaPercent.toStringAsFixed(1)}%) 📉';
      case TrendDirection.stable:
        return 'Estável (${trendDeltaPercent >= 0 ? '+' : ''}${trendDeltaPercent.toStringAsFixed(1)}%) ⚖️';
    }
  }

  String get trendLabelClean {
    switch (trendDirection) {
      case TrendDirection.improving:
        return 'Em Alta (+${trendDeltaPercent.toStringAsFixed(1)}%)';
      case TrendDirection.declining:
        return 'Em Queda (${trendDeltaPercent.toStringAsFixed(1)}%)';
      case TrendDirection.stable:
        return 'Estável (${trendDeltaPercent >= 0 ? '+' : ''}${trendDeltaPercent.toStringAsFixed(1)}%)';
    }
  }

  /// Gera um relatório textual completo e estruturado para cópia / compartilhamento
  String toPlainText() {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final buffer = StringBuffer();

    buffer.writeln('==============================================');
    buffer.writeln('📋 RELATÓRIO EXECUTIVO DE EVOLUÇÃO DAS REFEIÇÕES');
    buffer.writeln('==============================================');
    buffer.writeln('Gerado em: ${df.format(generatedAt)}');
    buffer.writeln('Filtro de Período: $periodLabel');
    buffer.writeln('Unidade(s): $unitFilter');
    buffer.writeln('');

    buffer.writeln('--- 📊 RESUMO GERAL DAS AVALIAÇÕES ---');
    buffer.writeln('• Total de Avaliações: $totalFeedbacks');
    buffer.writeln('• Comentários Registrados: $totalComments');
    buffer.writeln('• Fotos Anexadas: $totalPhotos');
    buffer.writeln('• Muito Boa: $muitoBoaCount (${excellenceRate.toStringAsFixed(1)}%)');
    buffer.writeln('• Boa: $boaCount (${totalFeedbacks > 0 ? ((boaCount / totalFeedbacks) * 100).toStringAsFixed(1) : '0.0'}%)');
    buffer.writeln('• Muito Ruim: $muitoRuimCount (${disapprovalRate.toStringAsFixed(1)}%)');
    buffer.writeln('• Taxa Geral de Satisfação: ${satisfactionRate.toStringAsFixed(1)}%');
    buffer.writeln('• Tendência Recente: $trendLabel - $trendSummary');
    buffer.writeln('');

    buffer.writeln('--- 🏢 COMPARATIVO POR UNIDADE ---');
    buffer.writeln('[Unidade Pedra]');
    buffer.writeln('  - Avaliações: ${pedraStats.totalFeedbacks} | Satisfação: ${pedraStats.satisfactionRate.toStringAsFixed(1)}% | Muito Ruim: ${pedraStats.muitoRuimCount}');
    buffer.writeln('  - Muito Boa: ${pedraStats.muitoBoaCount} | Comentários: ${pedraStats.commentCount}');
    buffer.writeln('[Unidade Vertente]');
    buffer.writeln('  - Avaliações: ${vertenteStats.totalFeedbacks} | Satisfação: ${vertenteStats.satisfactionRate.toStringAsFixed(1)}% | Muito Ruim: ${vertenteStats.muitoRuimCount}');
    buffer.writeln('  - Muito Boa: ${vertenteStats.muitoBoaCount} | Comentários: ${vertenteStats.commentCount}');
    buffer.writeln('');

    if (criticalTopics.isNotEmpty) {
      buffer.writeln('--- 🔍 PRINCIPAIS PONTOS DE ATENÇÃO (COMENTÁRIOS) ---');
      for (final topic in criticalTopics) {
        buffer.writeln('• ${topic.title} (${topic.count} menções)');
        if (topic.sampleSnippets.isNotEmpty) {
          buffer.writeln('  Exemplo citado: "${topic.sampleSnippets.first}"');
        }
      }
      buffer.writeln('');
    }

    if (positiveTopics.isNotEmpty) {
      buffer.writeln('--- ⭐ PRINCIPAIS ELOGIOS & PONTOS FORTES ---');
      for (final topic in positiveTopics) {
        buffer.writeln('• ${topic.title} (${topic.count} menções positivas)');
        if (topic.sampleSnippets.isNotEmpty) {
          buffer.writeln('  Exemplo citado: "${topic.sampleSnippets.first}"');
        }
      }
      buffer.writeln('');
    }

    buffer.writeln('--- 💡 DIAGNÓSTICO & PONTOS DE MELHORIA ---');
    for (int i = 0; i < improvementPoints.length; i++) {
      buffer.writeln('${i + 1}. ${improvementPoints[i]}');
    }
    buffer.writeln('');

    buffer.writeln('--- 🎯 PLANO DE AÇÃO RECOMENDADO ---');
    for (int i = 0; i < actionableRecommendations.length; i++) {
      buffer.writeln('${i + 1}. ${actionableRecommendations[i]}');
    }
    buffer.writeln('');
    buffer.writeln('==============================================');
    buffer.writeln('App Avalia Restaurante • Relatório Automatizado');
    buffer.writeln('==============================================');

    return buffer.toString();
  }
}

class ReportGenerator {
  /// Analisa a lista de feedbacks filtrados e extrai dados executivos e diagnósticos
  static ExecutiveReportData generate({
    required List<FeedbackItem> feedbacks,
    required String periodLabel,
    required String unitFilter,
  }) {
    final now = DateTime.now();
    final total = feedbacks.length;
    final commentsList = feedbacks.where((f) => f.message.trim().isNotEmpty).toList();
    final totalComments = commentsList.length;
    final totalPhotos = feedbacks.where((f) => f.imageUrl != null && f.imageUrl!.isNotEmpty).length;

    final muitoBoaCount = feedbacks.where((f) => f.foodRating == 'Muito Boa').length;
    final boaCount = feedbacks.where((f) => f.foodRating == 'Boa').length;
    final muitoRuimCount = feedbacks.where((f) => f.foodRating == 'Muito ruim').length;

    final satisfactionRate = total > 0 ? ((muitoBoaCount + boaCount) / total) * 100 : 0.0;
    final excellenceRate = total > 0 ? (muitoBoaCount / total) * 100 : 0.0;
    final disapprovalRate = total > 0 ? (muitoRuimCount / total) * 100 : 0.0;

    // Estatísticas por Unidade
    final pedraFeedbacks = feedbacks.where((f) => f.unit == 'Pedra').toList();
    final vertenteFeedbacks = feedbacks.where((f) => f.unit == 'Vertente').toList();

    final pedraStats = _calcUnitStats('Pedra', pedraFeedbacks);
    final vertenteStats = _calcUnitStats('Vertente', vertenteFeedbacks);

    // Análise de Tendência Temporal (divide os feedbacks ordenados no tempo ao meio)
    final sortedByDate = List<FeedbackItem>.from(feedbacks)..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    TrendDirection trendDir = TrendDirection.stable;
    double trendDelta = 0.0;
    String trendSummary = 'Volume insuficiente de registros para cálculo de tendência temporal.';

    if (sortedByDate.length >= 4) {
      final half = (sortedByDate.length / 2).floor();
      final firstHalf = sortedByDate.sublist(0, half);
      final secondHalf = sortedByDate.sublist(half);

      final sat1 = _calcSatisfaction(firstHalf);
      final sat2 = _calcSatisfaction(secondHalf);

      trendDelta = sat2 - sat1;

      if (trendDelta >= 5.0) {
        trendDir = TrendDirection.improving;
        trendSummary = 'Evolução positiva: o índice de aprovação recente subiu ${trendDelta.toStringAsFixed(1)}% em relação ao início do período.';
      } else if (trendDelta <= -5.0) {
        trendDir = TrendDirection.declining;
        trendSummary = 'Alerta de declínio: a aprovação recente caiu ${trendDelta.abs().toStringAsFixed(1)}% na segunda metade do período.';
      } else {
        trendDir = TrendDirection.stable;
        trendSummary = 'Estabilidade: o nível de satisfação manteve-se constante ao longo do período selecionado.';
      }
    } else if (total > 0) {
      trendSummary = 'Índice de satisfação consolidado em ${satisfactionRate.toStringAsFixed(1)}%.';
    }

    // Mineração e classificação de temas nos comentários
    final criticalTopics = <TopicInsight>[];
    final positiveTopics = <TopicInsight>[];

    _extractTopics(commentsList, criticalTopics, positiveTopics);

    // Elaboração dos Pontos de Melhoria (Diagnósticos)
    final improvementPoints = _buildImprovementPoints(
      total: total,
      disapprovalRate: disapprovalRate,
      criticalTopics: criticalTopics,
      pedraStats: pedraStats,
      vertenteStats: vertenteStats,
      unitFilter: unitFilter,
    );

    // Elaboração das Recomendações Acionáveis
    final actionableRecommendations = _buildRecommendations(
      criticalTopics: criticalTopics,
      disapprovalRate: disapprovalRate,
      pedraStats: pedraStats,
      vertenteStats: vertenteStats,
    );

    return ExecutiveReportData(
      generatedAt: now,
      periodLabel: periodLabel,
      unitFilter: unitFilter,
      totalFeedbacks: total,
      totalComments: totalComments,
      totalPhotos: totalPhotos,
      muitoBoaCount: muitoBoaCount,
      boaCount: boaCount,
      muitoRuimCount: muitoRuimCount,
      satisfactionRate: satisfactionRate,
      excellenceRate: excellenceRate,
      disapprovalRate: disapprovalRate,
      trendDirection: trendDir,
      trendDeltaPercent: trendDelta,
      trendSummary: trendSummary,
      pedraStats: pedraStats,
      vertenteStats: vertenteStats,
      criticalTopics: criticalTopics,
      positiveTopics: positiveTopics,
      improvementPoints: improvementPoints,
      actionableRecommendations: actionableRecommendations,
    );
  }

  static double _calcSatisfaction(List<FeedbackItem> list) {
    if (list.isEmpty) return 0.0;
    final good = list.where((f) => f.foodRating == 'Muito Boa' || f.foodRating == 'Boa').length;
    return (good / list.length) * 100;
  }

  static UnitStats _calcUnitStats(String name, List<FeedbackItem> list) {
    final total = list.length;
    final mb = list.where((f) => f.foodRating == 'Muito Boa').length;
    final b = list.where((f) => f.foodRating == 'Boa').length;
    final mr = list.where((f) => f.foodRating == 'Muito ruim').length;
    final c = list.where((f) => f.message.trim().isNotEmpty).length;

    final sat = total > 0 ? ((mb + b) / total) * 100 : 0.0;
    final exc = total > 0 ? (mb / total) * 100 : 0.0;

    return UnitStats(
      unitName: name,
      totalFeedbacks: total,
      muitoBoaCount: mb,
      boaCount: b,
      muitoRuimCount: mr,
      commentCount: c,
      satisfactionRate: sat,
      excellenceRate: exc,
    );
  }

  static void _extractTopics(
    List<FeedbackItem> comments,
    List<TopicInsight> outCritical,
    List<TopicInsight> outPositive,
  ) {
    final keywordsSalt = ['sal', 'salgado', 'salgada', 'insosso', 'sem gosto', 'tempero', 'apimentado', 'ardido', 'temperada'];
    final keywordsTempPoint = ['frio', 'fria', 'gelada', 'gelado', 'morno', 'morna', 'cru', 'crua', 'queimado', 'queimada', 'duro', 'dura', 'borrachuda', 'ressecada', 'seca', 'passado'];
    final keywordsVariety = ['variedade', 'opcao', 'opção', 'opcoes', 'opções', 'repetitivo', 'repetitiva', 'mesma coisa', 'salada', 'sobremesa', 'fruta', 'legumes', 'verde', 'trocar o cardapio', 'cardápio'];
    final keywordsServiceQueue = ['fila', 'demora', 'demorado', 'acabou', 'faltou', 'reposicao', 'reposição', 'repor', 'atendimento', 'funcionario', 'funcionário', 'grosseria', 'demorou'];
    final keywordsHygiene = ['cabelo', 'mosca', 'sujeira', 'sujo', 'suja', 'limpeza', 'oleo', 'óleo', 'gordura', 'gorduroso', 'gordurosa', 'cheiro'];
    final keywordsPraise = ['parabens', 'parabéns', 'delicia', 'delícia', 'excelente', 'perfeito', 'perfeita', 'maravilhoso', 'maravilhosa', 'saboroso', 'saborosa', 'gostoso', 'gostosa', 'otimo', 'ótimo', 'otima', 'ótima', 'muito bom', 'muito boa', 'adorei', 'top'];

    int countSalt = 0;
    int countTemp = 0;
    int countVar = 0;
    int countService = 0;
    int countHyg = 0;
    int countPraise = 0;

    final samplesSalt = <String>[];
    final samplesTemp = <String>[];
    final samplesVar = <String>[];
    final samplesService = <String>[];
    final samplesHyg = <String>[];
    final samplesPraise = <String>[];

    for (final f in comments) {
      final text = f.message.toLowerCase();

      // Verifica elogios
      if (_matchesAny(text, keywordsPraise) || f.foodRating == 'Muito Boa' || f.type == 'Elogio') {
        countPraise++;
        if (samplesPraise.length < 2 && f.message.trim().length > 5) {
          samplesPraise.add(f.message.trim());
        }
      }

      // Verifica pontos críticos
      if (_matchesAny(text, keywordsSalt)) {
        countSalt++;
        if (samplesSalt.length < 2) samplesSalt.add(f.message.trim());
      }
      if (_matchesAny(text, keywordsTempPoint)) {
        countTemp++;
        if (samplesTemp.length < 2) samplesTemp.add(f.message.trim());
      }
      if (_matchesAny(text, keywordsVariety)) {
        countVar++;
        if (samplesVar.length < 2) samplesVar.add(f.message.trim());
      }
      if (_matchesAny(text, keywordsServiceQueue)) {
        countService++;
        if (samplesService.length < 2) samplesService.add(f.message.trim());
      }
      if (_matchesAny(text, keywordsHygiene)) {
        countHyg++;
        if (samplesHyg.length < 2) samplesHyg.add(f.message.trim());
      }
    }

    if (countSalt > 0) {
      outCritical.add(TopicInsight(
        title: 'Tempero e Teor de Sal',
        category: 'Atenção',
        count: countSalt,
        sampleSnippets: samplesSalt,
        recommendation: 'Padronizar fichas técnicas e realizar degustação prévia do lote pelo nutricionista antes de liberar o buffet.',
      ));
    }

    if (countTemp > 0) {
      outCritical.add(TopicInsight(
        title: 'Temperatura e Ponto de Cocção',
        category: 'Atenção',
        count: countTemp,
        sampleSnippets: samplesTemp,
        recommendation: 'Calibrar balcões térmicos (banho-maria) para manter temperatura acima de 65°C e ajustar tempo de cozimento das proteínas.',
      ));
    }

    if (countVar > 0) {
      outCritical.add(TopicInsight(
        title: 'Variedade do Cardápio e Saladas',
        category: 'Atenção',
        count: countVar,
        sampleSnippets: samplesVar,
        recommendation: 'Introduzir rodízio semanal de guarnições e ampliar opções de saladas cruas e frutas frescas.',
      ));
    }

    if (countService > 0) {
      outCritical.add(TopicInsight(
        title: 'Velocidade de Reposição e Filas',
        category: 'Atenção',
        count: countService,
        sampleSnippets: samplesService,
        recommendation: 'Ajustar escala de abastecimento nos horários de pico (11h45 - 12h30) para evitar bandejas vazias.',
      ));
    }

    if (countHyg > 0) {
      outCritical.add(TopicInsight(
        title: 'Higiene e Gordura / Óleo',
        category: 'Atenção',
        count: countHyg,
        sampleSnippets: samplesHyg,
        recommendation: 'Reforçar boas práticas de manipulação (EPIs/toucas) e controlar o escoamento de frituras e refogados.',
      ));
    }

    if (countPraise > 0) {
      outPositive.add(TopicInsight(
        title: 'Aprovação de Sabor e Qualidade',
        category: 'Destaque Positivo',
        count: countPraise,
        sampleSnippets: samplesPraise,
        recommendation: 'Compartilhar os elogios com a equipe da cozinha como incentivo e replicar as receitas de sucesso.',
      ));
    }

    // Ordena os tópicos críticos pelo maior número de menções
    outCritical.sort((a, b) => b.count.compareTo(a.count));
  }

  static bool _matchesAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  static List<String> _buildImprovementPoints({
    required int total,
    required double disapprovalRate,
    required List<TopicInsight> criticalTopics,
    required UnitStats pedraStats,
    required UnitStats vertenteStats,
    required String unitFilter,
  }) {
    final list = <String>[];

    if (total == 0) {
      list.add('Sem registros no período selecionado para formulação de diagnósticos.');
      return list;
    }

    if (disapprovalRate > 25.0) {
      list.add('Taxa de desaprovação elevada (${disapprovalRate.toStringAsFixed(1)}% de "Muito Ruim"): requer intervenção e alinhamento imediato com a gestão de alimentos.');
    } else if (disapprovalRate > 10.0) {
      list.add('Nível moderado de insatisfação (${disapprovalRate.toStringAsFixed(1)}%): atenção pontual aos comentários com queixas frequentes.');
    } else {
      list.add('Índice de desaprovação controlado em nível baixo (${disapprovalRate.toStringAsFixed(1)}%), demonstrando boa aceitação geral.');
    }

    if (criticalTopics.isNotEmpty) {
      final top = criticalTopics.first;
      list.add('Foco prioritário apontado pelos colaboradores: "${top.title}" acumulou ${top.count} queixas nos comentários.');
      if (criticalTopics.length > 1) {
        final sec = criticalTopics[1];
        list.add('Ponto secundário de atenção: "${sec.title}" com ${sec.count} menções.');
      }
    } else {
      list.add('Não foram detectadas queixas temáticas recorrentes nos comentários deste período.');
    }

    if (unitFilter == 'Todas' && pedraStats.totalFeedbacks > 0 && vertenteStats.totalFeedbacks > 0) {
      final diff = (pedraStats.satisfactionRate - vertenteStats.satisfactionRate).abs();
      if (diff > 12.0) {
        final leader = pedraStats.satisfactionRate > vertenteStats.satisfactionRate ? 'Pedra' : 'Vertente';
        final lower = leader == 'Pedra' ? 'Vertente' : 'Pedra';
        list.add('Disparidade entre unidades: a unidade $leader apresenta aprovação de ${(leader == 'Pedra' ? pedraStats.satisfactionRate : vertenteStats.satisfactionRate).toStringAsFixed(1)}% contra ${(lower == 'Pedra' ? pedraStats.satisfactionRate : vertenteStats.satisfactionRate).toStringAsFixed(1)}% da unidade $lower. Recomenda-se benchmark dos processos da unidade $leader.');
      }
    }

    return list;
  }

  static List<String> _buildRecommendations({
    required List<TopicInsight> criticalTopics,
    required double disapprovalRate,
    required UnitStats pedraStats,
    required UnitStats vertenteStats,
  }) {
    final list = <String>[];

    for (final topic in criticalTopics.take(3)) {
      list.add(topic.recommendation);
    }

    if (list.isEmpty) {
      list.add('Manter o padrão de preparo e controle de qualidade adotado no período.');
      list.add('Continuar incentivando o registro de feedbacks e comentários pelos colaboradores.');
    } else {
      list.add('Realizar reunião quinzenal de alinhamento de cardápio com os cozinheiros e nutricionista responsável.');
      list.add('Acompanhar a evolução dos índices na próxima semana para medir o impacto das melhorias aplicadas.');
    }

    return list;
  }
}
