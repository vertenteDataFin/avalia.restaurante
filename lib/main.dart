import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/unit_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RestaurantFeedbackApp());
}

class RestaurantFeedbackApp extends StatelessWidget {
  const RestaurantFeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avalia Restaurante',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const UnitSelectionScreen(),
    );
  }
}
