import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← FIX 1: локаль
import 'package:couple_app/core/theme/app_theme.dart';
import 'package:couple_app/core/services/notification_service.dart';
import 'package:couple_app/core/services/storage_service.dart';
import 'package:couple_app/core/router/router.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/auth/providers/profile_provider.dart';
import 'package:couple_app/features/home/pet_system.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService().init();

  // FIX 1: инициализируем локаль ru для DateFormat
  await initializeDateFormatting('ru', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase уже инициализирован
  }

  await NotificationService().init();

  final storage = StorageService();
  final savedPetCounter = storage.loadPetCounter();

  runApp(
    ProviderScope(
      overrides: [
        petTaskCounterProvider.overrideWith((ref) => savedPetCounter),
      ],
      child: const CoupleApp(),
    ),
  );
}

class CoupleApp extends ConsumerStatefulWidget {
  const CoupleApp({super.key});

  @override
  ConsumerState<CoupleApp> createState() => _CoupleAppState();
}

class _CoupleAppState extends ConsumerState<CoupleApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksNotifierProvider.notifier).initStorage();
      ref.read(profileProvider.notifier).initStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
