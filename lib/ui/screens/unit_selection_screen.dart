import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/feedback_service.dart';
import 'public_feedback_screen.dart';
import 'admin_login_screen.dart';
import 'admin_dashboard_screen.dart';

class UnitSelectionScreen extends StatelessWidget {
  const UnitSelectionScreen({super.key});

  void _navigateToUnit(BuildContext context, String unit) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicFeedbackScreen(unit: unit)),
    );
  }

  void _navigateToAdmin(BuildContext context) {
    final feedbackService = FeedbackService();
    if (feedbackService.currentAdmin != null &&
        feedbackService.currentAdmin!.isApproved) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliação do Restaurante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Área do Administrador',
            onPressed: () => _navigateToAdmin(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho de Boas-Vindas
                  Card(
                    elevation: 3,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              size: 48,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Seja bem-vindo(a)!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selecione a unidade em que você realizou sua refeição para registrar sua opinião e nos ajudar a melhorar:',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Escolha a Unidade',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão/Card Unidade Pedra
                  _buildUnitCard(
                    context: context,
                    unitName: 'Pedra',
                    subtitle: 'Restaurante Unidade Pedra',
                    icon: Icons.storefront_rounded,
                    accentColor: AppTheme.primaryGreen,
                    onTap: () => _navigateToUnit(context, 'Pedra'),
                  ),

                  const SizedBox(height: 16),

                  // Botão/Card Unidade Vertente
                  _buildUnitCard(
                    context: context,
                    unitName: 'Vertente',
                    subtitle: 'Restaurante Unidade Vertente',
                    icon: Icons.location_city_rounded,
                    accentColor: const Color(
                      0xFF0277BD,
                    ), // Azul elegante complementar
                    onTap: () => _navigateToUnit(context, 'Vertente'),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard({
    required BuildContext context,
    required String unitName,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: accentColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 36, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unidade $unitName',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: accentColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
