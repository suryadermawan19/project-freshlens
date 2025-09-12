// lib/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/login_screen.dart';
import 'package:freshlens_ai_app/register_screen.dart';
import 'package:page_transition/page_transition.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Latar belakang dengan gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade200,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo Aplikasi
                  Image.asset(
                    'assets/images/logo.png', // Pastikan path logo benar
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  
                  // Nama Aplikasi
                  Text(
                    'FreshLens AI',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Slogan
                  Text(
                    'Jaga kesegaran, kurangi limbah.\nSelamat datang!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // Tombol Masuk
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, PageTransition(
                          type: PageTransitionType.fade,
                          child: const LoginScreen(),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('MASUK'),
                    ), 
                  ),
                  const SizedBox(height: 16),
                  
                  // Tombol Daftar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, PageTransition(
                          type: PageTransitionType.fade,
                          child: const RegisterScreen(),
                        ));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('DAFTAR'),
                    ),
                  ),
                   const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}