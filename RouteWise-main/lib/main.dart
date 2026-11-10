import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/route_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Fallback if .env is missing or invalid
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => RouteProvider(),
      child: const RouteWiseApp(),
    ),
  );
}

class RouteWiseApp extends StatelessWidget {
  const RouteWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'RouteWise',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}
