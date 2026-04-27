import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../widgets/intro_components.dart'; // Import các widget đã tách
import 'home_screen.dart';
import 'register_screen.dart';

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

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          setState(() {
            _scrollProgress -= details.delta.dy / _scrollSensitivity;
            _scrollProgress = _scrollProgress.clamp(0.0, math.pi);
            _lottieController.value = _scrollProgress / math.pi;
          });
        },
        child: AnimatedBuilder(
          animation: _lottieController,
          builder: (context, child) {
            double combinedProgress = math.max(_scrollProgress / math.pi, _lottieController.value);
            double uiOpacity = (1.0 - (combinedProgress * 1.5)).clamp(0.0, 1.0);
            double spreadOffset = combinedProgress * 1000;

            return Stack(
              children: [
            // --- a. SÁCH LOTTIE 3D ---
            Align(
              alignment: const Alignment(0, -0.2),
              child: Transform.scale(
                scale: 1.0 + (combinedProgress * 2.0) + (_lottieController.value * 20.0),
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
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      
                      Transform.translate(
                        offset: Offset(-spreadOffset, 0),
                        child: Opacity(
                          opacity: uiOpacity,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SMARTLIB", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF80A1BA), height: 1.0)),
                              Text("SYSTEM ONLINE", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF91C4C3))),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 220), 
                      Transform.translate(
                        offset: Offset(spreadOffset, 0),
                        child: Opacity(opacity: uiOpacity, child: const Text("Updated from library core just now", style: TextStyle(color: Color(0xFF80A1BA), fontSize: 13))),
                      ),
                      const SizedBox(height: 15),
                      
                      Transform.translate(
                        offset: Offset(0, spreadOffset),
                        child: Opacity(opacity: uiOpacity, child: const VerificationBar()),
                      ),
                      const SizedBox(height: 20),
                      
                      Opacity(
                        opacity: uiOpacity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Transform.translate(
                                offset: Offset(-spreadOffset, 0),
                                child: _buildActionButton(
                                  title: "Nhập NFC",
                                  icon: Icons.nfc_rounded,
                                  color: const Color(0xFF91C4C3),
                                  onTap: () async {
                                    await _lottieController.forward();
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                                      ).then((_) {
                                        _lottieController.reset();
                                        setState(() {
                                          _scrollProgress = 0.0;
                                        });
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Transform.translate(
                                offset: Offset(spreadOffset, 0),
                                child: _buildActionButton(
                                  title: "Đăng ký",
                                  icon: Icons.app_registration_rounded,
                                  color: const Color(0xFFB4DEBD),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                    );
                                  },

                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // --- Đã bỏ hướng dẫn vuốt xuống ---
              ],
            );
          },
        ),
      ),
    );
  }
}