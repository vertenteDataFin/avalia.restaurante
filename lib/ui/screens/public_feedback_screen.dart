import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/feedback_service.dart';
import 'admin_login_screen.dart';
import 'admin_dashboard_screen.dart';

class PublicFeedbackScreen extends StatefulWidget {
  final String unit;

  const PublicFeedbackScreen({
    super.key,
    this.unit = 'Pedra',
  });

  @override
  State<PublicFeedbackScreen> createState() => _PublicFeedbackScreenState();
}

class _PublicFeedbackScreenState extends State<PublicFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _foodRating; // "Muito ruim", "Boa", "Muito Boa"
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _showRatingError = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _ratingOptions = [
    {
      'label': 'Muito ruim',
      'subtitle': 'Insatisfeito',
      'icon': Icons.sentiment_very_dissatisfied_rounded,
      'activeColor': const Color(0xFFD32F2F),
      'bgColor': const Color(0xFFFFEBEE),
      'borderColor': const Color(0xFFFFCDD2),
    },
    {
      'label': 'Boa',
      'subtitle': 'Satisfeito',
      'icon': Icons.sentiment_satisfied_rounded,
      'activeColor': const Color(0xFFF57C00),
      'bgColor': const Color(0xFFFFF3E0),
      'borderColor': const Color(0xFFFFE0B2),
    },
    {
      'label': 'Muito Boa',
      'subtitle': 'Excelente',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'activeColor': const Color(0xFF2E7D32),
      'bgColor': const Color(0xFFE8F5E9),
      'borderColor': const Color(0xFFC8E6C9),
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadImage(XFile img) async {
    final bytes = await img.readAsBytes();
    if (bytes.length > 1040000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto muito grande. Tente uma imagem menor ou com menor resolução.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    setState(() {
      _selectedImage = img;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
              title: const Text('Tirar Foto com a Câmera'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  // No Web, parâmetros de redimensionamento causam erro de memória;
                  // no nativo eles funcionam normalmente.
                  final img = kIsWeb
                      ? await _picker.pickImage(source: ImageSource.camera)
                      : await _picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 60,
                        );
                  if (img != null) await _loadImage(img);
                } catch (e) {
                  debugPrint('Erro ao abrir câmera: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível acessar a câmera. Tente pela galeria.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              title: const Text('Escolher da Galeria'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final img = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 60,
                  );
                  if (img != null) await _loadImage(img);
                } catch (e) {
                  debugPrint('Erro ao abrir galeria: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível acessar a galeria.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) return;

    if (_foodRating == null) {
      setState(() => _showRatingError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, avalie a qualidade da comida selecionando uma opção.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final success = await FeedbackService().addFeedback(
          unit: widget.unit,
          foodRating: _foodRating!,
          type: 'Geral',
          message: _messageController.text.trim(),
          imageUrl: _selectedImage?.path,
          imageBytes: _selectedImageBytes,
        );

        if (success) {
          _messageController.clear();
          setState(() {
            _selectedImage = null;
            _selectedImageBytes = null;
            _foodRating = null;
            _showRatingError = false;
          });

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Enviado com Sucesso!'),
                  ),
                ],
              ),
              content: const Text(
                'Sua avaliação foi recebida pela equipe do restaurante. Agradecemos sua colaboração para melhorarmos a cada dia!',
                textAlign: TextAlign.justify,
                style: TextStyle(height: 1.3),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('OK', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocorreu um erro ao enviar seu feedback. Por favor, tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackService = FeedbackService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliação do Restaurante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Área de Gestão Admin',
            onPressed: () {
              if (feedbackService.currentAdmin != null && feedbackService.currentAdmin!.isApproved) {
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
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card compacto com indicação da Unidade Selecionada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                'Unidade ${widget.unit}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.swap_horiz, color: Colors.white, size: 13),
                                SizedBox(width: 3),
                                Text(
                                  'Trocar',
                                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sua opinião é fundamental!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Avalie a qualidade da refeição de forma rápida e simples.',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Painel de Seleção Obrigatório: Qualidade da Comida
              Row(
                children: [
                  const Text(
                    'Qualidade da Comida ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const Text(
                    '*',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(Obrigatório)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                children: _ratingOptions.map((opt) {
                  final label = opt['label'] as String;
                  final subtitle = opt['subtitle'] as String;
                  final icon = opt['icon'] as IconData;
                  final activeColor = opt['activeColor'] as Color;
                  final bgColor = opt['bgColor'] as Color;
                  final borderColor = opt['borderColor'] as Color;
                  final isSelected = _foodRating == label;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _foodRating = label;
                              _showRatingError = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor : bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? activeColor
                                    : (_showRatingError ? Colors.red : borderColor),
                                width: isSelected ? 2.2 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: activeColor.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 28,
                                        color: isSelected ? Colors.white : activeColor,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        subtitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                          color: isSelected ? Colors.white70 : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -4,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: activeColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_showRatingError) ...[
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'Selecione uma opção de avaliação acima.',
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Mensagem (Opcional)
              const Text(
                'Sua Mensagem / Comentário (Opcional):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _messageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Caso deseje, escreva aqui detalhes adicionais...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (val) => null,
              ),
              const SizedBox(height: 10),

              // Anexo de Imagem (Opcional)
              const Text(
                'Foto da Refeição (Opcional):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: _selectedImageBytes != null ? 130 : 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImage != null ? AppTheme.primaryGreen : Colors.grey[300]!,
                      width: _selectedImage != null ? 2 : 1,
                    ),
                  ),
                  child: _selectedImageBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.memory(
                                _selectedImageBytes!,
                                width: double.infinity,
                                height: 130,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 14,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                  onPressed: () => setState(() {
                                    _selectedImage = null;
                                    _selectedImageBytes = null;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 20, color: AppTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text(
                              'Clique para anexar foto da refeição',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Botão Enviar
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'ENVIAR AVALIAÇÃO',
                              style: TextStyle(fontSize: 15, letterSpacing: 0.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
