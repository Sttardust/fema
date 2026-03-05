import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_router.dart';
import 'core/theme/app_colors.dart';

bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Firebase — requires google-services.json in android/app/
  // If missing, the app will still launch but Firebase features will be unavailable.
  try {
    await Firebase.initializeApp();
    _firebaseInitialized = true;
  } catch (e) {
    debugPrint(
      '[FEMA] Firebase initialization failed: $e\n'
      'Ensure google-services.json is placed in android/app/ and '
      'GoogleService-Info.plist is placed in ios/Runner/.',
    );
  }

  runApp(
    ProviderScope(
      child: FemaApp(firebaseReady: _firebaseInitialized),
    ),
  );
}

class FemaApp extends ConsumerWidget {
  final bool firebaseReady;
  const FemaApp({super.key, this.firebaseReady = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FEMA',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      builder: (context, child) => child!,
    );
  }
}
