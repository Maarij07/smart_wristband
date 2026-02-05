import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseConfig {
  static Future<void> initializeApp() async {
    try {
      // Try to load environment variables
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Could not load .env file: \$e
      // Continue anyway, as we'll use fallback values
    }

    // Get values with fallbacks
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_APP_ID'] ?? '';
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
    final measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';
    final databaseURL = dotenv.env['FIREBASE_DATABASE_URL'] ?? '';

    // Check if we have the required values
    if (apiKey.isEmpty || appId.isEmpty || authDomain.isEmpty || projectId.isEmpty) {
      // Missing Firebase configuration values. Please check your .env file.
      // Initialize with default config
      await Firebase.initializeApp();
    } else {
      // Initialize Firebase with the loaded values
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          authDomain: authDomain,
          projectId: projectId,
          storageBucket: storageBucket,
          messagingSenderId: messagingSenderId,
          measurementId: measurementId,
          databaseURL: databaseURL.isNotEmpty ? databaseURL : null,
        ),
      );
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseDatabase get realtimeDb => FirebaseDatabase.instance;
}