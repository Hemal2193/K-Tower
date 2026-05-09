// import 'dart:io';

// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:k_tower/homepage.dart';
// import 'package:k_tower/login_page.dart';
// import 'package:k_tower/model/hive.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// const String authGateRoute = '/';
// const String loginRoute = '/login';
// const String homeRoute = '/home';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Disable app rotation - lock to portrait mode only
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   // Initialize Hive
//   await Hive.initFlutter();

//   // Register the adapter for EntryModel
//   Hive.registerAdapter(EntryModelAdapter());

//   await Supabase.initialize(
//     url: 'https://ygqlooyqakfqpkvjqbrr.supabase.co',
//     anonKey:
//         'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlncWxvb3lxYWtmcXBrdmpxYnJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3Mjk4NjQsImV4cCI6MjA4OTMwNTg2NH0.FZ0Ct8mORXqQ9ogSOvo5S5ZyZGK9radkKqUe3B4V91E',
//   );

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       initialRoute: authGateRoute,
//       routes: {
//         authGateRoute: (context) => const AuthGate(),
//         loginRoute: (context) => const LoginPage(),
//         homeRoute: (context) => const HomePage(),
//       },
//     );
//   }
// }

// class AuthGate extends StatefulWidget {
//   const AuthGate({super.key});

//   @override
//   State<AuthGate> createState() => _AuthGateState();
// }

// class _AuthGateState extends State<AuthGate> {
//   final supabase = Supabase.instance.client;
//   bool _hasCheckedAuth = false;
//   bool _isCheckingAuth = false;
//   bool _isSessionReady = false;

//   @override
//   void initState() {
//     super.initState();
//     // Wait for Supabase to confirm the session state
//     // This prevents the LoginPage flash when user is already logged in
//     _waitForSession();
//   }

//   Future<void> _waitForSession() async {
//     // If session already exists, we're ready immediately
//     if (supabase.auth.currentSession != null) {
//       if (mounted) {
//         setState(() {
//           _isSessionReady = true;
//         });
//       }
//       return;
//     }

//     // Wait for the first auth state change (session restore or confirm null)
//     // with a timeout to prevent infinite waiting
//     try {
//       await supabase.auth.onAuthStateChange.first.timeout(
//         const Duration(seconds: 3),
//       );
//     } catch (_) {
//       // Timeout or error - proceed anyway
//     }

//     if (mounted) {
//       setState(() {
//         _isSessionReady = true;
//       });
//     }
//   }

//   Future<bool> isUserAllowed() async {
//     final user = supabase.auth.currentUser;

//     if (user == null) return false;

//     final deviceId = await getDeviceId();

//     final result = await supabase
//         .from('allowed')
//         .select()
//         .eq('email', user.email.toString())
//         .eq('device_id', deviceId)
//         .maybeSingle();

//     return result != null;
//   }

//   Future<void> handleUnauthorizedUser() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     final deviceId = await getDeviceId();
//     final userEmail = user.email;

//     try {
//       // Insert into pending table
//       await supabase.from('pending').upsert({
//         'email': userEmail,
//         'device_id': deviceId,
//       });

//       // Show snackbar safely after widget is mounted
//       if (mounted) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Request sent for approval'),
//                 duration: Duration(seconds: 3),
//               ),
//             );
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Error processing request: $e'),
//                 duration: Duration(seconds: 3),
//               ),
//             );
//           }
//         });
//       }
//     } finally {
//       // Sign out user
//       await supabase.auth.signOut();
//     }
//   }

//   Future<String> getDeviceId() async {
//     final deviceInfo = DeviceInfoPlugin();

//     if (Platform.isAndroid) {
//       final androidInfo = await deviceInfo.androidInfo;
//       return androidInfo.id;
//     } else if (Platform.isIOS) {
//       final iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.identifierForVendor ?? 'unknown_ios';
//     } else {
//       return 'unsupported_platform';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Show loading screen until session is ready
//     // This prevents the LoginPage flash when user is already logged in
//     if (!_isSessionReady) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     final auth = supabase.auth;
//     final session = auth.currentSession;

//     // ❌ Not logged in
//     if (session == null) {
//       _hasCheckedAuth = false; // Reset flag when not logged in
//       return const LoginPage();
//     }

//     // ✅ Logged in → check DB
//     // Only check authorization once per session to prevent multiple DB calls
//     if (!_hasCheckedAuth && !_isCheckingAuth) {
//       _isCheckingAuth = true;
//       _hasCheckedAuth = true;

//       WidgetsBinding.instance.addPostFrameCallback((_) async {
//         if (!mounted) return;

//         try {
//           final isAllowed = await isUserAllowed();

//           if (!mounted) return;

//           if (!isAllowed) {
//             await handleUnauthorizedUser();
//           }
//           // If allowed, the widget will rebuild and show HomePage
//         } catch (e) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Authentication error: $e')),
//             );
//             await supabase.auth.signOut();
//           }
//         } finally {
//           if (mounted) {
//             setState(() {
//               _isCheckingAuth = false;
//             });
//           }
//         }
//       });
//     }

//     // While checking → show loading (not LoginPage)
//     if (_isCheckingAuth) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     // After check:
//     // If user still logged in → allowed
//     final currentUser = supabase.auth.currentUser;

//     if (currentUser != null) {
//       return const HomePage();
//     } else {
//       return const LoginPage();
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:k_tower/homepage.dart';
import 'package:k_tower/login_page.dart';
import 'package:k_tower/model/hive.dart';
import 'package:k_tower/splash.dart';
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

// class AuthGate extends StatefulWidget {
//   const AuthGate({super.key});

//   @override
//   State<AuthGate> createState() => _AuthGateState();
// }

// class _AuthGateState extends State<AuthGate> {
//   final supabase = Supabase.instance.client;

//   bool _hasCheckedAuth = false;
//   bool _isCheckingAuth = false;
//   bool _isSessionReady = false;

//   @override
//   void initState() {
//     super.initState();
//     _waitForSession();
//   }

//   Future<void> _waitForSession() async {
//     if (supabase.auth.currentSession != null) {
//       setState(() => _isSessionReady = true);
//       return;
//     }

//     try {
//       await supabase.auth.onAuthStateChange.first.timeout(
//         const Duration(seconds: 3),
//       );
//     } catch (_) {}

//     if (mounted) {
//       setState(() => _isSessionReady = true);
//     }
//   }

//   Future<bool> isUserAllowed() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) return false;

//     final deviceId = await getDeviceId();

//     final result = await supabase
//         .from('allowed')
//         .select()
//         .eq('email', user.email.toString())
//         .eq('device_id', deviceId)
//         .maybeSingle();

//     return result != null;
//   }

//   Future<void> handleUnauthorizedUser() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     final deviceId = await getDeviceId();

//     try {
//       await supabase.from('pending').upsert({
//         'email': user.email,
//         'device_id': deviceId,
//       });

//       if (mounted) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Request sent for approval'),
//               ),
//             );
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Error: $e')),
//             );
//           }
//         });
//       }
//     } finally {
//       await supabase.auth.signOut();
//     }
//   }

//   Future<String> getDeviceId() async {
//     final deviceInfo = DeviceInfoPlugin();

//     if (Platform.isAndroid) {
//       final androidInfo = await deviceInfo.androidInfo;
//       return androidInfo.id;
//     } else if (Platform.isIOS) {
//       final iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.identifierForVendor ?? 'unknown_ios';
//     } else {
//       return 'unsupported_platform';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ✅ Only loader allowed → initial session restore
//     if (!_isSessionReady) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     // ✅ Listen to auth state changes for login/logout events
//     return StreamBuilder<AuthState>(
//       stream: supabase.auth.onAuthStateChange,
//       builder: (context, snapshot) {
//         final session = snapshot.data?.session ?? supabase.auth.currentSession;

//         // ❌ Not logged in
//         if (session == null) {
//           _hasCheckedAuth = false;
//           _isCheckingAuth = false;
//           return const LoginPage();
//         }

//         // 🔍 Check authorization once per session
//         if (!_hasCheckedAuth && !_isCheckingAuth) {
//           _isCheckingAuth = true;
//           _hasCheckedAuth = true;

//           WidgetsBinding.instance.addPostFrameCallback((_) async {
//             if (!mounted) return;

//             try {
//               final allowed = await isUserAllowed();

//               if (!mounted) return;

//               if (!allowed) {
//                 await handleUnauthorizedUser();
//               }
//             } catch (e) {
//               if (mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Auth error: $e')),
//                 );
//                 await supabase.auth.signOut();
//               }
//             } finally {
//               if (mounted) {
//                 setState(() => _isCheckingAuth = false);
//               }
//             }
//           });
//         }

//         // While checking authorization, show loader
//         if (_isCheckingAuth) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         // ✅ If still logged in → allowed
//         if (supabase.auth.currentUser != null) {
//           return const HomePage();
//         }

//         return const LoginPage();
//       },
//     );
//   }
// }
