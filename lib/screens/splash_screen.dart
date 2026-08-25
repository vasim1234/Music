import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;
  
  const SplashScreen({
    super.key, 
    required this.onThemeChanged, 
    required this.isDarkMode
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              onThemeChanged: widget.onThemeChanged,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF0F0F0F), const Color(0xFF1A1A1A)]
              : [const Color(0xFF0F172A), const Color(0xFFD946EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)],
                ),
                child: const Icon(Icons.music_note, size: 100, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "BHAI BHAI APP",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
            const SizedBox(height: 10),
            const Text("Feel The Rhythm", style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Switch(
                    value: widget.isDarkMode,
                    onChanged: (value) {
                      widget.onThemeChanged(value);
                    },
                    activeColor: Colors.deepPurple,
                    inactiveThumbColor: Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(isDark ? 'Dark' : 'Light', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
