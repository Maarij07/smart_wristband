import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/user_context.dart';
import 'services/ble_connection_provider.dart';
import 'services/messaging_provider.dart';
import 'config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserContext()),
        ChangeNotifierProvider(create: (_) => BleConnectionProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
      ],
      child: MaterialApp(
        title: 'Status Band',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'SF Pro Text',
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF000000),
            onPrimary: Color(0xFFFFFFFF),
            secondary: Color(0xFFEEEEEE),
            onSecondary: Color(0xFF000000),
            surface: Color(0xFFFFFFFF),
            onSurface: Color(0xFF000000),
            error: Color(0xFF000000),
            onError: Color(0xFFFFFFFF),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}