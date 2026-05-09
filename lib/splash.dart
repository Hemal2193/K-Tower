import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_tower/homepage.dart';
import 'package:k_tower/login_page.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    final double height = MediaQuery.of(context).size.height;

    return AnimatedSplashScreen(
      splash: Center(
        child: Lottie.asset(
          'assets/ksplash.json',
          fit: BoxFit.fitHeight,
          frameRate: FrameRate.max,
          repeat: false,
        ),
      ), // or your splash widget/image
      nextScreen: session == null ? const LoginPage() : const HomePage(),
      backgroundColor: Colors.deepPurple,
      splashIconSize: height,
      duration: 1000,
    );
  }
}
