import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../widgets/intro_components.dart'; // Import các widget đã tách

class ProfessionalIntroScreen extends StatefulWidget {
  const ProfessionalIntroScreen({super.key});

  @override
  State<ProfessionalIntroScreen> createState() => _ProfessionalIntroScreenState();
}

class _ProfessionalIntroScreenState extends State<ProfessionalIntroScreen> with SingleTickerProviderStateMixin {
  double _scrollProgress = 0.0;
  final double _scrollSensitivity = 800.0;
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double uiOpacity = (1.0 - (_scrollProgress * 3)).clamp(0.0, 1.0);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          setState(() {
            _scrollProgress -= details.delta.dy / _scrollSensitivity;
            _scrollProgress = _scrollProgress.clamp(0.0, math.pi);
            _lottieController.value = _scrollProgress / math.pi;
          });
        },
        child: Stack(
          children: [
            // --- a. SÁCH LOTTIE 3D ---
            Align(
              alignment: const Alignment(0, -0.2),
              child: Transform.scale(
                scale: 1.0 + ((_scrollProgress / math.pi) * 2.0), 
                child: SizedBox(
                  width: 300, 
                  height: 300,
                  child: Lottie.asset(
                    'assets/animations/books_open.json', 
                    controller: _lottieController, 
                    onLoaded: (composition) {
                      _lottieController.duration = composition.duration;
                    },
                  ),
                ),
              ),
            ),

            // --- b. GIAO DIỆN TẢN RA 4 PHƯƠNG ---
            Positioned.fill(
              child: Opacity(
                opacity: (1.0 - (_scrollProgress / (0.7 * math.pi))).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(offset: Offset(0, -_scrollProgress * 600), child: Opacity(opacity: uiOpacity, child: const IntroHeader())),
                      const SizedBox(height: 30),
                      
                      Transform.translate(
                        offset: Offset(-_scrollProgress * 600, 0),
                        child: Opacity(
                          opacity: uiOpacity,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SMARTLIB", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                              Text("SYSTEM ONLINE", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 220), 
                      Transform.translate(
                        offset: Offset(_scrollProgress * 600, 0),
                        child: Opacity(opacity: uiOpacity, child: const Text("Updated from library core just now", style: TextStyle(color: Colors.grey, fontSize: 13))),
                      ),
                      const SizedBox(height: 15),
                      
                      Transform.translate(
                        offset: Offset(0, _scrollProgress * 600),
                        child: Opacity(opacity: uiOpacity, child: const VerificationBar()),
                      ),
                      const SizedBox(height: 20),
                      
                      Opacity(
                        opacity: uiOpacity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Transform.translate(offset: Offset(-_scrollProgress * 600, 0), child: const CustomIconButton(icon: Icons.lock_outline_rounded)),
                            Transform.translate(offset: Offset(-_scrollProgress * 300, 0), child: const CustomIconButton(icon: Icons.lock_open_rounded)),
                            Transform.translate(offset: Offset(0, _scrollProgress * 600), child: const CustomIconButton(icon: Icons.lightbulb_outline_rounded)), 
                            Transform.translate(offset: Offset(_scrollProgress * 300, 0), child: const CustomIconButton(icon: Icons.search_rounded)),
                            Transform.translate(offset: Offset(_scrollProgress * 600, 0), child: const CustomIconButton(icon: Icons.ac_unit_rounded)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Opacity(
                        opacity: uiOpacity,
                        child: Row(
                          children: [
                            Transform.translate(offset: Offset(-_scrollProgress * 600, 0), child: const DemoCard(icon: Icons.library_books_outlined, title: "Book Finder", subtitle: "Library Main Hall")),
                            const SizedBox(width: 15),
                            Transform.translate(offset: Offset(_scrollProgress * 600, 0), child: const DemoCard(icon: Icons.satellite_alt_rounded, title: "AI Scanner", subtitle: "Remote Recognition")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // --- Hướng dẫn vuốt ---
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Opacity(
                opacity: uiOpacity,
                child: const Column(
                  children: [
                    Icon(Icons.keyboard_double_arrow_down_rounded, size: 30, color: Colors.blueAccent),
                    Text("Vuốt xuống để mở sách", style: TextStyle(color: Colors.blueAccent)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}