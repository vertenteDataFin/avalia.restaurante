class FeedbackItem {
  final String id;
  final String unit; // "Pedra" ou "Vertente"
  final String foodRating; // "Muito ruim", "Boa", "Muito Boa"
  final String type; // "Reclamação", "Sugestão", "Elogio"
  final String message;
  final String? imageUrl;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    this.unit = 'Pedra',
    this.foodRating = 'Boa',
    required this.type,
    required this.message,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit': unit,
      'foodRating': foodRating,
      'type': type,
      'message': message,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] as String,
      unit: (json['unit'] as String?) ?? 'Pedra',
      foodRating: (json['foodRating'] as String?) ?? 'Boa',
      type: (json['type'] as String?) ?? 'Reclamação',
      message: (json['message'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

