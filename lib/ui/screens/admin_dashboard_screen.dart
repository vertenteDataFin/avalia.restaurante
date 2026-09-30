import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/report_generator.dart';
import '../../core/utils/pdf_report_generator.dart';
import '../../data/models/feedback_item.dart';
import '../../data/models/admin_user.dart';
import '../../data/services/feedback_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Filtro de Período, Unidade e Qualidade da Comida
  String _selectedPeriod = 'Todas'; // 'Todas', 'Hoje', '7 dias', '30 dias', 'Este Mês', 'Personalizado'
  String _selectedUnit = 'Todas'; // 'Todas', 'Pedra', 'Vertente'
  String _selectedRatingFilter = 'Total'; // 'Total', 'Muito ruim', 'Boa', 'Muito Boa'
  DateTimeRange? _customDateRange;

  bool _isCanManageUsers = true;

  @override
  void initState() {
    super.initState();
    final admin = FeedbackService().currentAdmin;
    _isCanManageUsers = admin?.canManageUsers ?? false;
    _initTabController();
  }

  void _initTabController() {
    final tabCount = _isCanManageUsers ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedRatingFilter = 'Total';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkTabController(bool canManage) {
    if (_isCanManageUsers != canManage) {
      _isCanManageUsers = canManage;
      _tabController.dispose();
      _initTabController();
    }
  }

  List<FeedbackItem> _filterByUnit(List<FeedbackItem> feedbacks) {
    if (_selectedUnit == 'Todas') return feedbacks;
    return feedbacks.where((f) => f.unit == _selectedUnit).toList();
  }

  List<FeedbackItem> _filterByPeriod(List<FeedbackItem> feedbacks) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'Hoje':
        final startOfToday = DateTime(now.year, now.month, now.day);
        return feedbacks.where((f) => f.createdAt.isAfter(startOfToday) || f.createdAt.isAtSameMomentAs(startOfToday)).toList();
      case '7 dias':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return feedbacks.where((f) => f.createdAt.isAfter(sevenDaysAgo)).toList();
      case '30 dias':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return feedbacks.where((f) => f.createdAt.isAfter(thirtyDaysAgo)).toList();
      case 'Este Mês':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return feedbacks.where((f) => f.createdAt.isAfter(startOfMonth) || f.createdAt.isAtSameMomentAs(startOfMonth)).toList();
      case 'Personalizado':
        if (_customDateRange == null) return feedbacks;
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        return feedbacks.where((f) => f.createdAt.isAfter(start) && f.createdAt.isBefore(end)).toList();
      case 'Todas':
      default:
        return feedbacks;
    }
  }

  String _getPeriodDescription() {
    switch (_selectedPeriod) {
      case 'Hoje':
        return 'Hoje (${DateFormat('dd/MM/yyyy').format(DateTime.now())})';
      case '7 dias':
        return 'Últimos 7 dias';
      case '30 dias':
        return 'Últimos 30 dias';
      case 'Este Mês':
        return 'Este Mês (${DateFormat('MM/yyyy').format(DateTime.now())})';
      case 'Personalizado':
        if (_customDateRange != null) {
          final df = DateFormat('dd/MM/yyyy');
          return '${df.format(_customDateRange!.start)} até ${df.format(_customDateRange!.end)}';
        }
        return 'Período Personalizado';
      case 'Todas':
      default:
        return 'Todo o Período';
    }
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'Personalizado';
      });
    }
  }

  void _openFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImageWidget(imageUrl, isFull: true),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteFeedback(BuildContext context, FeedbackItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Registro'),
        content: const Text('Deseja realmente excluir este registro permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FeedbackService().deleteFeedback(item.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registro excluído com sucesso.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = FeedbackService();
    final admin = service.currentAdmin;
    final canManage = admin?.canManageUsers ?? false;
    _checkTabController(canManage);

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final allFeedbacks = service.feedbacks;
        final pendingAdmins = service.pendingAdmins;
        final activeUsers = service.activeUsers;

        // Feedbacks filtrados pelo período e unidade selecionados
        final periodFiltered = _filterByPeriod(allFeedbacks);
        final filteredFeedbacks = _filterByUnit(periodFiltered);

        // Feedbacks que possuem comentários de texto
        final commentFeedbacks = filteredFeedbacks.where((f) => f.message.trim().isNotEmpty).toList();

        // Contagens por qualidade da comida (Geral)
        final muitoRuimCount = filteredFeedbacks.where((f) => f.foodRating == 'Muito ruim').length;
        final boaCount = filteredFeedbacks.where((f) => f.foodRating == 'Boa').length;
        final muitoBoaCount = filteredFeedbacks.where((f) => f.foodRating == 'Muito Boa').length;
        final totalFiltered = filteredFeedbacks.length;

        // Feedbacks exibidos na aba de Avaliações
        final displayedFeedbacks = _selectedRatingFilter == 'Total'
            ? filteredFeedbacks
            : filteredFeedbacks.where((f) => f.foodRating == _selectedRatingFilter).toList();

        // Feedbacks exibidos na aba de Comentários
        final displayedComments = _selectedRatingFilter == 'Total'
            ? commentFeedbacks
            : commentFeedbacks.where((f) => f.foodRating == _selectedRatingFilter).toList();

        final tabsList = <Widget>[
          Tab(text: 'Avaliações (${filteredFeedbacks.length})'),
          Tab(text: 'Comentários (${commentFeedbacks.length})'),
          const Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assessment_outlined, size: 16),
                SizedBox(width: 6),
                Text('Relatório Executivo'),
              ],
            ),
          ),
        ];

        if (canManage) {
          tabsList.add(
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Gestão de Usuários'),
                  if (pendingAdmins.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pendingAdmins.length}',
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final tabViewsList = <Widget>[
          // Aba 1: Avaliações
          _buildFeedbacksTabView(
            feedbacks: displayedFeedbacks,
            totalCount: totalFiltered,
            muitoRuimCount: muitoRuimCount,
            boaCount: boaCount,
            muitoBoaCount: muitoBoaCount,
            admin: admin,
            context: context,
            isCommentsOnly: false,
          ),

          // Aba 2: Comentários (mostrar somente comentários)
          _buildFeedbacksTabView(
            feedbacks: displayedComments,
            totalCount: commentFeedbacks.length,
            muitoRuimCount: commentFeedbacks.where((f) => f.foodRating == 'Muito ruim').length,
            boaCount: commentFeedbacks.where((f) => f.foodRating == 'Boa').length,
            muitoBoaCount: commentFeedbacks.where((f) => f.foodRating == 'Muito Boa').length,
            admin: admin,
            context: context,
            isCommentsOnly: true,
          ),

          // Aba 3: Relatório Executivo
          _buildExecutiveReportTab(filteredFeedbacks, admin),
        ];

        if (canManage) {
          // Aba 4: Gestão de Usuários (Aprovações e Usuários Ativos)
          tabViewsList.add(
            _buildUserManagementTab(pendingAdmins, activeUsers, service),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Painel de Gestão'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sair',
                onPressed: () {
                  service.logoutAdmin();
                  Navigator.pop(context);
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: AppTheme.accentAmber,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: tabsList,
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: tabViewsList,
          ),
        );
      },
    );
  }

  Widget _buildFeedbacksTabView({
    required List<FeedbackItem> feedbacks,
    required int totalCount,
    required int muitoRuimCount,
    required int boaCount,
    required int muitoBoaCount,
    required AdminUser? admin,
    required BuildContext context,
    required bool isCommentsOnly,
  }) {
    final bool canDelete = admin?.canDelete ?? false;

    return Column(
      children: [
        // Faixa com dados do Usuário logado e seu papel (Admin ou Visualizador)
        if (admin != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: admin.isAdmin
                      ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                      : Colors.blue.withValues(alpha: 0.15),
                  radius: 18,
                  child: Icon(
                    admin.isAdmin ? Icons.admin_panel_settings : Icons.visibility,
                    color: admin.isAdmin ? AppTheme.primaryGreen : const Color(0xFF0277BD),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.name.isNotEmpty ? admin.name : admin.email,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        admin.email,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: admin.isAdmin ? AppTheme.primaryGreen : const Color(0xFF0277BD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        admin.isAdmin ? Icons.shield : Icons.remove_red_eye_outlined,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        admin.roleLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Barra de Filtros: Unidade e Período
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              // Filtro Unidade
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      isExpanded: true,
                      icon: const Icon(Icons.storefront, size: 18, color: AppTheme.primaryGreen),
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'Todas', child: Text('Unidade: Todas')),
                        DropdownMenuItem(value: 'Pedra', child: Text('Pedra')),
                        DropdownMenuItem(value: 'Vertente', child: Text('Vertente')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedUnit = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Filtro Período
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      isExpanded: true,
                      icon: const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryGreen),
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'Todas', child: Text('Todo Período')),
                        DropdownMenuItem(value: 'Hoje', child: Text('Hoje')),
                        DropdownMenuItem(value: '7 dias', child: Text('Últimos 7 dias')),
                        DropdownMenuItem(value: '30 dias', child: Text('Últimos 30 dias')),
                        DropdownMenuItem(value: 'Este Mês', child: Text('Este Mês')),
                        DropdownMenuItem(value: 'Personalizado', child: Text('Personalizado...')),
                      ],
                      onChanged: (val) {
                        if (val == 'Personalizado') {
                          _selectCustomDateRange(context);
                        } else if (val != null) {
                          setState(() => _selectedPeriod = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Aviso discreto quando estiver na aba de comentários
        if (isCommentsOnly)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.comment_outlined, size: 16, color: Color(0xFF0277BD)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mostrando somente avaliações que contêm comentários',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0277BD)),
                  ),
                ),
              ],
            ),
          ),

        // Cards de Métricas clicáveis (Muito ruim, Boa, Muito Boa, Total)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _buildMetricCard(
                label: 'Muito ruim',
                filterValue: 'Muito ruim',
                count: muitoRuimCount,
                total: totalCount,
                color: Colors.red[700]!,
                bgColor: const Color(0xFFFFEBEE),
                icon: Icons.sentiment_very_dissatisfied,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                label: 'Boa',
                filterValue: 'Boa',
                count: boaCount,
                total: totalCount,
                color: Colors.amber[800]!,
                bgColor: const Color(0xFFFFF8E1),
                icon: Icons.sentiment_satisfied,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                label: 'Muito Boa',
                filterValue: 'Muito Boa',
                count: muitoBoaCount,
                total: totalCount,
                color: const Color(0xFF005A2B),
                bgColor: const Color(0xFFE8F5E9),
                icon: Icons.sentiment_very_satisfied,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                label: 'Total',
                filterValue: 'Total',
                count: totalCount,
                total: totalCount,
                color: Colors.blueGrey[800]!,
                bgColor: const Color(0xFFECEFF1),
                icon: Icons.bar_chart,
                isTotal: true,
              ),
            ],
          ),
        ),

        // Tag indicadora quando houver filtro ativo pelas métricas
        if (_selectedRatingFilter != 'Total')
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filtrado por: $_selectedRatingFilter',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    setState(() => _selectedRatingFilter = 'Total');
                  },
                  child: const Icon(Icons.close, size: 16, color: Colors.black54),
                ),
              ],
            ),
          ),

        // Lista de Avaliações / Comentários
        Expanded(
          child: _buildFeedbackList(
            feedbacks,
            _selectedRatingFilter,
            isCommentsOnly: isCommentsOnly,
            canDelete: canDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String filterValue,
    required int count,
    required int total,
    required Color color,
    required Color bgColor,
    required IconData icon,
    bool isTotal = false,
  }) {
    final double percentage = total > 0 ? (count / total) * 100 : 0;
    final isSelected = _selectedRatingFilter == filterValue;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (filterValue == 'Total') {
                _selectedRatingFilter = 'Total';
              } else if (_selectedRatingFilter == filterValue) {
                _selectedRatingFilter = 'Total'; // Clicar novamente volta a exibir todas
              } else {
                _selectedRatingFilter = filterValue;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? bgColor : bgColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
                if (!isTotal)
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.85),
                    ),
                  ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackList(
    List<FeedbackItem> items,
    String typeLabel, {
    bool isCommentsOnly = false,
    required bool canDelete,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              typeLabel == 'Muito Boa'
                  ? Icons.sentiment_very_satisfied_rounded
                  : typeLabel == 'Boa'
                      ? Icons.sentiment_satisfied_rounded
                      : typeLabel == 'Muito ruim'
                          ? Icons.sentiment_very_dissatisfied_rounded
                          : Icons.assignment_outlined,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              isCommentsOnly
                  ? (typeLabel == 'Total'
                      ? 'Nenhum comentário encontrado no período.'
                      : 'Nenhum comentário de "$typeLabel" no período.')
                  : (typeLabel == 'Total'
                      ? 'Nenhum registro encontrado no período.'
                      : 'Nenhum registro de "$typeLabel" no período.'),
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final hasPhoto = item.imageUrl != null && item.imageUrl!.isNotEmpty;
        final hasMessage = item.message.trim().isNotEmpty;

        Color ratingColor;
        IconData ratingIcon;
        switch (item.foodRating) {
          case 'Muito ruim':
            ratingColor = Colors.red[700]!;
            ratingIcon = Icons.sentiment_very_dissatisfied;
            break;
          case 'Muito Boa':
            ratingColor = const Color(0xFF005A2B);
            ratingIcon = Icons.sentiment_very_satisfied;
            break;
          case 'Boa':
          default:
            ratingColor = Colors.amber[800]!;
            ratingIcon = Icons.sentiment_satisfied;
            break;
        }

        final unitColor = item.unit == 'Vertente' ? const Color(0xFF0277BD) : AppTheme.primaryGreen;

        Widget buildUnitBadge() {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: unitColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: unitColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, size: 14, color: unitColor),
                const SizedBox(width: 5),
                Text(
                  item.unit.isNotEmpty ? item.unit : 'Unidade',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: unitColor,
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildRatingBadge({bool expand = false}) {
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: ratingColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ratingColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ratingIcon, size: 15, color: ratingColor),
                const SizedBox(width: 5),
                Text(
                  item.foodRating.isNotEmpty ? item.foodRating : 'Avaliação',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ratingColor,
                  ),
                ),
              ],
            ),
          );
          if (expand) {
            return Expanded(child: badge);
          }
          return badge;
        }

        Widget buildPhotoWidget() {
          return GestureDetector(
            onTap: () => _openFullImageDialog(context, item.imageUrl!),
            child: Stack(
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: _buildImageWidget(item.imageUrl!, isFull: false),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.zoom_in, color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildMessageWidget({double minHeight = 38}) {
          return Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              item.message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.black87,
              ),
            ),
          );
        }

        final deleteButtonWidget = InkWell(
          onTap: () => _confirmDeleteFeedback(context, item),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, color: Colors.red[600], size: 18),
                const SizedBox(width: 4),
                Text(
                  'Excluir',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );

        final dateWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _dateFormat.format(item.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        // Layout de acordo com os 3 cenários:
        Widget contentRow;

        if (hasPhoto) {
          contentRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildUnitBadge(),
                  const SizedBox(height: 6),
                  buildRatingBadge(),
                ],
              ),
              const SizedBox(width: 10),
              if (hasMessage) ...[
                Expanded(
                  child: buildMessageWidget(minHeight: 80),
                ),
                const SizedBox(width: 10),
              ] else ...[
                const Spacer(),
              ],
              buildPhotoWidget(),
            ],
          );
        } else if (hasMessage) {
          contentRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildUnitBadge(),
              const SizedBox(width: 8),
              buildRatingBadge(),
              const SizedBox(width: 8),
              Expanded(
                child: buildMessageWidget(minHeight: 38),
              ),
            ],
          );
        } else {
          contentRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildUnitBadge(),
              const SizedBox(width: 8),
              buildRatingBadge(expand: true),
            ],
          );
        }

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                contentRow,
                const SizedBox(height: 8),
                // Rodapé com exclusão (se for admin) e data
                Row(
                  mainAxisAlignment: canDelete
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (canDelete) deleteButtonWidget,
                    dateWidget,
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(String imageUrl, {required bool isFull}) {
    final double imgHeight = isFull ? 240 : 85;
    final double imgWidth = isFull ? double.infinity : 85;
    final BoxFit imageFit = isFull ? BoxFit.contain : BoxFit.cover;

    if (imageUrl.startsWith('data:image') || imageUrl.length > 200) {
      try {
        final base64Data = imageUrl.contains(',') ? imageUrl.split(',')[1] : imageUrl;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: imgWidth,
          height: imgHeight,
          fit: imageFit,
          errorBuilder: (ctx, err, stack) => _buildImageError(isFull),
        );
      } catch (_) {}
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: imgWidth,
        height: imgHeight,
        fit: imageFit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            width: imgWidth,
            height: isFull ? 220 : 90,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 2),
          );
        },
        errorBuilder: (ctx, err, stack) => _buildImageError(isFull),
      );
    }

    if (!kIsWeb) {
      try {
        final file = File(imageUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: imgWidth,
            height: imgHeight,
            fit: imageFit,
            errorBuilder: (ctx, err, stack) => _buildImageError(isFull),
          );
        }
      } catch (_) {}
    }

    return _buildImageError(isFull);
  }

  Widget _buildImageError(bool isFull) {
    return Container(
      width: isFull ? double.infinity : 90,
      height: isFull ? 160 : 90,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_photo, color: AppTheme.primaryGreen, size: 28),
          const SizedBox(height: 4),
          Text(
            'Foto Anexada',
            style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab(
    List<AdminUser> pendingAdmins,
    List<AdminUser> activeUsers,
    FeedbackService service,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção 1: Solicitações Pendentes
          Row(
            children: [
              const Icon(Icons.person_add_outlined, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Solicitações Pendentes de Acesso',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (pendingAdmins.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendingAdmins.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (pendingAdmins.isEmpty)
            Card(
              elevation: 0,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Nenhuma solicitação pendente no momento.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...pendingAdmins.map((user) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      const Text(
                        'Aprovar perfil como:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Botão Recusar
                          OutlinedButton(
                            onPressed: () async {
                              await service.rejectAdmin(user.uid);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Solicitação de ${user.name} recusada.')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[300]!),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Recusar', style: TextStyle(fontSize: 12)),
                          ),

                          // Botão Visualizador
                          ElevatedButton.icon(
                            onPressed: () async {
                              await service.approveAdmin(user.uid, role: 'viewer');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${user.name} aprovado como Visualizador!'),
                                  backgroundColor: const Color(0xFF0277BD),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0277BD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('Visualizador', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),

                          // Botão Administrador
                          ElevatedButton.icon(
                            onPressed: () async {
                              await service.approveAdmin(user.uid, role: 'admin');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${user.name} aprovado como Administrador!'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.shield, size: 14),
                            label: const Text('Administrador', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Seção 2: Usuários Ativos / Cadastrados
          Row(
            children: [
              const Icon(Icons.manage_accounts_outlined, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                'Usuários Ativos (${activeUsers.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Gerencie o papel de cada usuário ativo ou revogue o acesso:',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),

          if (activeUsers.isEmpty)
            Card(
              elevation: 0,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Center(
                  child: Text('Nenhum outro usuário ativo cadastrado.'),
                ),
              ),
            )
          else
            ...activeUsers.map((user) {
              final isCurrentLoggedUser = service.currentAdmin?.uid == user.uid;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Dados do Usuário (Nome e E-mail) sem avatar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrentLoggedUser) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Você', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Dropdown Unificado: Administrador / Visualizador / Excluir
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isAdmin
                              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: user.isAdmin ? AppTheme.primaryGreen : const Color(0xFF0277BD),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: user.role,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: user.isAdmin ? AppTheme.primaryGreen : const Color(0xFF0277BD),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'admin',
                                child: Text('Administrador'),
                              ),
                              const DropdownMenuItem(
                                value: 'viewer',
                                child: Text('Visualizador'),
                              ),
                              if (!isCurrentLoggedUser)
                                DropdownMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red[700], size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Excluir',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: isCurrentLoggedUser
                                ? null // Usuário atual não pode alterar/excluir o próprio acesso aqui
                                : (selectedAction) async {
                                    if (selectedAction == null) return;

                                    if (selectedAction == 'delete') {
                                      // Abre diálogo de confirmação de exclusão
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Text('Excluir Usuário?'),
                                          content: Text('Deseja realmente revogar o acesso e excluir ${user.name}?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                await service.deleteUser(user.uid);
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Usuário ${user.name} excluído com sucesso.'),
                                                    backgroundColor: Colors.red[700],
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                                              child: const Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (selectedAction != user.role) {
                                      await service.updateUserRole(user.uid, selectedAction);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Papel de ${user.name} alterado para ${selectedAction == "admin" ? "Administrador" : "Visualizador"}!'),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleExportPdf(ExecutiveReportData report) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 10),
              Text('Gerando PDF de página única...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      await PdfReportGenerator.exportPdf(report);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('PDF exportado com sucesso!'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar PDF: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _handlePrintPdf(ExecutiveReportData report) async {
    try {
      await PdfReportGenerator.printPdf(report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir impressão: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Widget _buildExecutiveReportTab(List<FeedbackItem> feedbacks, AdminUser? admin) {
    final report = ReportGenerator.generate(
      feedbacks: feedbacks,
      periodLabel: _getPeriodDescription(),
      unitFilter: _selectedUnit,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra Superior de Controles: Filtros Rápidos + Botões de Ação
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Filtros (Unidade e Período)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Dropdown Unidade
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                isDense: true,
                                icon: const Icon(Icons.storefront, size: 16, color: AppTheme.primaryGreen),
                                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                                items: const [
                                  DropdownMenuItem(value: 'Todas', child: Text('Unidade: Todas')),
                                  DropdownMenuItem(value: 'Pedra', child: Text('Pedra')),
                                  DropdownMenuItem(value: 'Vertente', child: Text('Vertente')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedUnit = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          // Dropdown Período
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPeriod,
                                isDense: true,
                                icon: const Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryGreen),
                                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                                items: const [
                                  DropdownMenuItem(value: 'Todas', child: Text('Todo Período')),
                                  DropdownMenuItem(value: 'Hoje', child: Text('Hoje')),
                                  DropdownMenuItem(value: '7 dias', child: Text('Últimos 7 dias')),
                                  DropdownMenuItem(value: '30 dias', child: Text('Últimos 30 dias')),
                                  DropdownMenuItem(value: 'Este Mês', child: Text('Este Mês')),
                                  DropdownMenuItem(value: 'Personalizado', child: Text('Personalizado...')),
                                ],
                                onChanged: (val) {
                                  if (val == 'Personalizado') {
                                    _selectCustomDateRange(context);
                                  } else if (val != null) {
                                    setState(() => _selectedPeriod = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Botões de Ação: Exportar PDF e Recalcular
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Análise e métricas recalculadas com sucesso!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              side: const BorderSide(color: AppTheme.primaryGreen),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Recalcular', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _handleExportPdf(report),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('Exportar em PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (feedbacks.isEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Sem dados suficientes no período selecionado',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Altere os filtros de período ou unidade acima para gerar a análise executiva.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // DOCUMENTO EXECUTIVO PRINCIPAL
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho do Documento
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.assessment, color: AppTheme.primaryGreen, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'RELATÓRIO EXECUTIVO',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Unidade: $_selectedUnit',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Evolução da Qualidade & Diagnóstico das Refeições',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(report.generatedAt)} • Período: ${report.periodLabel}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // SEÇÃO 1: PAINEL DE KPIS EXECUTIVOS
                        const Text(
                          '1. Indicadores Principais de Desempenho (KPIs)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 650;
                            return GridView.count(
                              crossAxisCount: isMobile ? 2 : 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: isMobile ? 1.15 : 1.4,
                              children: [
                                // KPI 1: Taxa de Satisfação
                                _buildReportKpiCard(
                                  title: 'Taxa de Satisfação',
                                  value: '${report.satisfactionRate.toStringAsFixed(1)}%',
                                  subtitle: '${report.muitoBoaCount + report.boaCount} de ${report.totalFeedbacks} votos',
                                  icon: Icons.thumb_up_alt_outlined,
                                  color: report.satisfactionRate >= 80
                                      ? const Color(0xFF005A2B)
                                      : report.satisfactionRate >= 65
                                          ? Colors.amber[800]!
                                          : Colors.red[700]!,
                                  bgColor: report.satisfactionRate >= 80
                                      ? const Color(0xFFE8F5E9)
                                      : report.satisfactionRate >= 65
                                          ? const Color(0xFFFFF8E1)
                                          : const Color(0xFFFFEBEE),
                                ),

                                // KPI 2: Tendência Temporal
                                _buildReportKpiCard(
                                  title: 'Tendência Recente',
                                  value: report.trendLabel,
                                  subtitle: report.trendDirection == TrendDirection.improving
                                      ? 'Curva ascendente'
                                      : report.trendDirection == TrendDirection.declining
                                          ? 'Atenção a declínio'
                                          : 'Nível estável',
                                  icon: report.trendDirection == TrendDirection.improving
                                      ? Icons.trending_up
                                      : report.trendDirection == TrendDirection.declining
                                          ? Icons.trending_down
                                          : Icons.trending_flat,
                                  color: report.trendDirection == TrendDirection.improving
                                      ? const Color(0xFF005A2B)
                                      : report.trendDirection == TrendDirection.declining
                                          ? Colors.red[700]!
                                          : Colors.blueGrey[800]!,
                                  bgColor: report.trendDirection == TrendDirection.improving
                                      ? const Color(0xFFE8F5E9)
                                      : report.trendDirection == TrendDirection.declining
                                          ? const Color(0xFFFFEBEE)
                                          : const Color(0xFFECEFF1),
                                ),

                                // KPI 3: Taxa de Excelência (Muito Boa)
                                _buildReportKpiCard(
                                  title: 'Índice Excelência',
                                  value: '${report.excellenceRate.toStringAsFixed(1)}%',
                                  subtitle: '${report.muitoBoaCount} votos "Muito Boa"',
                                  icon: Icons.star_outline,
                                  color: const Color(0xFF005A2B),
                                  bgColor: const Color(0xFFE8F5E9),
                                ),

                                // KPI 4: Taxa de Desaprovação (Muito Ruim)
                                _buildReportKpiCard(
                                  title: 'Desaprovação',
                                  value: '${report.disapprovalRate.toStringAsFixed(1)}%',
                                  subtitle: '${report.muitoRuimCount} votos "Muito Ruim"',
                                  icon: Icons.warning_amber_outlined,
                                  color: report.disapprovalRate > 15 ? Colors.red[700]! : Colors.grey[700]!,
                                  bgColor: report.disapprovalRate > 15 ? const Color(0xFFFFEBEE) : Colors.grey[100]!,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Faixa Explicativa da Tendência
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: report.trendDirection == TrendDirection.improving
                                ? Colors.green.withValues(alpha: 0.08)
                                : report.trendDirection == TrendDirection.declining
                                    ? Colors.red.withValues(alpha: 0.08)
                                    : Colors.blue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: report.trendDirection == TrendDirection.improving
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : report.trendDirection == TrendDirection.declining
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : Colors.blue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                report.trendDirection == TrendDirection.improving
                                    ? Icons.insights
                                    : report.trendDirection == TrendDirection.declining
                                        ? Icons.error_outline
                                        : Icons.info_outline,
                                color: report.trendDirection == TrendDirection.improving
                                    ? AppTheme.primaryGreen
                                    : report.trendDirection == TrendDirection.declining
                                        ? Colors.red[700]
                                        : const Color(0xFF0277BD),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  report.trendSummary,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: report.trendDirection == TrendDirection.improving
                                        ? const Color(0xFF005A2B)
                                        : report.trendDirection == TrendDirection.declining
                                            ? Colors.red[900]
                                            : Colors.blueGrey[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 36),

                        // SEÇÃO 2: COMPARATIVO DIRETO POR UNIDADE
                        const Text(
                          '2. Comparativo Direto entre Unidades (Pedra vs Vertente)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 650;
                            if (isMobile) {
                              return Column(
                                children: [
                                  _buildUnitComparisonCard(report.pedraStats, AppTheme.primaryGreen),
                                  const SizedBox(height: 10),
                                  _buildUnitComparisonCard(report.vertenteStats, const Color(0xFF0277BD)),
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  Expanded(child: _buildUnitComparisonCard(report.pedraStats, AppTheme.primaryGreen)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildUnitComparisonCard(report.vertenteStats, const Color(0xFF0277BD))),
                                ],
                              );
                            }
                          },
                        ),

                        const Divider(height: 36),

                        // SEÇÃO 3: ANÁLISE DOS COMENTÁRIOS E PONTOS CRÍTICOS
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              '3. Mineração de Tópicos nos Comentários',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${report.totalComments} comentários analisados',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (report.criticalTopics.isEmpty && report.positiveTopics.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.speaker_notes_off_outlined, color: Colors.grey[400], size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Nenhum comentário de texto registrado no período para extração de tópicos específicos.',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          if (report.criticalTopics.isNotEmpty) ...[
                            Text(
                              'Pontos de Atenção Mais Frequentes:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red[800]),
                            ),
                            const SizedBox(height: 8),
                            ...report.criticalTopics.map((topic) => _buildTopicInsightCard(topic, isCritical: true)),
                            const SizedBox(height: 12),
                          ],

                          if (report.positiveTopics.isNotEmpty) ...[
                            Text(
                              'Destaques Positivos & Elogios:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green[800]),
                            ),
                            const SizedBox(height: 8),
                            ...report.positiveTopics.map((topic) => _buildTopicInsightCard(topic, isCritical: false)),
                          ],
                        ],

                        const Divider(height: 36),

                        // SEÇÃO 4: SÍNTESE DO DIAGNÓSTICO
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.analytics, color: AppTheme.accentAmber, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '4. Síntese do Diagnóstico Executivo',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: report.improvementPoints.map((point) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const Divider(height: 36),

                        // SEÇÃO 5: PLANO DE AÇÃO RECOMENDADO
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.assignment_turned_in, color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '5. Plano de Ação Recomendado (Cozinha & Operação)',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: report.actionableRecommendations.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final action = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$index',
                                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        action,
                                        style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Botões Inferiores de Exportação (PDF, Impressão e Cópia)
                        Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _handleExportPdf(report),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Baixar Relatório em PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _handlePrintPdf(report),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                  side: const BorderSide(color: AppTheme.primaryGreen),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.print, size: 16),
                                label: const Text('Imprimir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final text = report.toPlainText();
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Texto do relatório copiado com sucesso!'),
                                      backgroundColor: AppTheme.primaryGreen,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[800],
                                  side: BorderSide(color: Colors.grey[400]!),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.content_copy, size: 16),
                                label: const Text('Copiar Texto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitComparisonCard(UnitStats stats, Color unitColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: unitColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, color: unitColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unidade ${stats.unitName}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: unitColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: unitColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${stats.totalFeedbacks} avaliações',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: unitColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Barra de Satisfação
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Taxa de Satisfação (Muito Boa + Boa):',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${stats.satisfactionRate.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stats.satisfactionRate >= 75 ? AppTheme.primaryGreen : Colors.red[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.totalFeedbacks > 0 ? (stats.satisfactionRate / 100).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(stats.satisfactionRate >= 75 ? AppTheme.primaryGreen : Colors.amber[800]!),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),

          // Detalhamento dos Votos
          Row(
            children: [
              Expanded(
                child: _buildMiniStatPill('Muito Boa', '${stats.muitoBoaCount}', const Color(0xFF005A2B), const Color(0xFFE8F5E9)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniStatPill('Boa', '${stats.boaCount}', Colors.amber[900]!, const Color(0xFFFFF8E1)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniStatPill('Muito Ruim', '${stats.muitoRuimCount}', Colors.red[700]!, const Color(0xFFFFEBEE)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatPill(String label, String count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[800]), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildTopicInsightCard(TopicInsight topic, {required bool isCritical}) {
    final themeColor = isCritical ? Colors.red[700]! : const Color(0xFF005A2B);
    final themeBg = isCritical ? const Color(0xFFFFF5F5) : const Color(0xFFF1F8E9);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(isCritical ? Icons.error_outline : Icons.check_circle_outline, color: themeColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  topic.title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: themeColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${topic.count} ${topic.count == 1 ? "menção" : "menções"}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor),
                ),
              ),
            ],
          ),
          if (topic.sampleSnippets.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('❝ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Expanded(
                    child: Text(
                      topic.sampleSnippets.first,
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber[900]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ação sugerida: ${topic.recommendation}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[800], fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}