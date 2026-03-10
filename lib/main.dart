import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/ble_navigation_handler.dart';
import 'services/user_context.dart';
import 'services/ble_connection_provider.dart';
import 'services/ble_foreground_service.dart';
import 'services/messaging_provider.dart';
import 'config/firebase_config.dart';

/// Global navigator key — lets us navigate from outside the widget tree if needed.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeApp();

  // Configure the Android foreground-service notification channel once at startup.
  BleForegroundService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserContext()),
        ChangeNotifierProvider(create: (_) => BleConnectionProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // After the first frame, try to reconnect to the last known device.
    // Providers are accessible here because MyApp is a child of MultiProvider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleConnectionProvider>().attemptAutoReconnect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Status Band',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
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
      // BleNavigationHandler wraps every screen — SOS can be shown from anywhere.
      builder: (context, child) =>
          BleNavigationHandler(child: child ?? const SizedBox.shrink()),
      home: const SplashScreen(),
    );
  }
}
