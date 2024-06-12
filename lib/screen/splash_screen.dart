import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:presensi_app/screen/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    // Delayed navigation to the login screen after 3 seconds
    Future.delayed(const Duration(seconds: 3)).then((value) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
            (route) => false,
      );
    });
    // Building the splash screen UI
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Displaying the logo image
            Image.asset(
              'assets/images/logo_polbeng.png',
              width: 128,
            ),
            const SizedBox(height: 8,),
            // Showing the app name
            Text(
              'PresensiApp',
              style: GoogleFonts.manrope(
                fontSize: 34,
                color: const Color(0xFF12A3DA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
