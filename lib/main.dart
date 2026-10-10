import 'package:flutter/material.dart';
import 'presentation/main_tab_screen.dart';

void main() {
  runApp(const PDFUtilityApp());
}

class PDFUtilityApp extends StatelessWidget {
  const PDFUtilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Engineering Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.teal,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}