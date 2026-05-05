import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../screens/isbn_scanner_screen.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "QUÉT MÃ",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF80A1BA),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Sử dụng AI để nhận diện sách hoặc quét NFC để mượn sách nhanh chóng",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              
              // Lottie Animation for Scanning
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Center(
                  child: Lottie.asset(
                    'assets/animations/books_open.json', // Reuse existing animation
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
              
              _buildScanButton(
                context,
                title: "Quét Mã Vạch (ISBN)",
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFF91C4C3),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IsbnScannerScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildScanButton(
                context,
                title: "Chạm NFC Mượn Sách",
                icon: Icons.nfc_rounded,
                color: const Color(0xFF80A1BA),
                onTap: () {
                  // TODO: Implement NFC Scanner
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
