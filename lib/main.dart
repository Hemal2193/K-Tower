import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:k_tower/homepage.dart';
import 'package:k_tower/login_page.dart';
import 'package:k_tower/model/hive.dart';
import 'package:k_tower/splash.dart';
import 'package:k_tower/services/entry_sync_service.dart';
import 'package:k_tower/services/sync_queue_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabse_config.dart';

const String authGateRoute = '/';
const String loginRoute = '/login';
const String homeRoute = '/home';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  Hive.registerAdapter(EntryModelAdapter());

  await Supabase.initialize(
    url: SupabseConfig.supabaseUrl,
    anonKey: SupabseConfig.supabaseKey,
  );

  // Pre-open Hive boxes during startup to eliminate box-opening latency
  // when navigating to HomePage or HistoryPage
  await Future.wait([
    Hive.openBox<EntryModel>(EntrySyncService.entriesBoxName),
    Hive.openBox<dynamic>(SyncQueueService.queueBoxName),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // initialRoute: authGateRoute,
      home: Splash(),

      routes: {
        // authGateRoute: (context) => const AuthGate(),
        loginRoute: (context) => const LoginPage(),
        homeRoute: (context) => const HomePage(),
      },
    );
  }
}