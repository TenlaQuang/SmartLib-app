import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../services/api_service.dart';
import '../widgets/intro_components.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'nfc_registration_screen.dart';

class ProfessionalIntroScreen extends StatefulWidget {
  const ProfessionalIntroScreen({super.key});

  @override
  State<ProfessionalIntroScreen> createState() => _ProfessionalIntroScreenState();
}

class _ProfessionalIntroScreenState extends State<ProfessionalIntroScreen> with SingleTickerProviderStateMixin {
  double _scrollProgress = 0.0;
  final double _scrollSensitivity = 800.0;
  late AnimationController _lottieController;
  final ApiService _apiService = ApiService();
  bool _isScanning = false;

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
                                    await _startNfcLogin();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Transform.translate(
                                offset: Offset(spreadOffset, 0),
                                child: _buildActionButton(
                                  title: "Đăng ký thẻ",
                                  icon: Icons.contactless_rounded,
                                  color: const Color(0xFFB4DEBD),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const NfcRegistrationScreen()),
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

  Future<void> _startNfcLogin() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        _showManualNfcDialog();
        return;
      }

      _showScanningBottomSheet();

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            await HapticFeedback.heavyImpact();
            final List<int> identifier = tag.data['isodep']?['identifier'] ?? 
                                         tag.data['nfca']?['identifier'] ?? 
                                         tag.data['mifareultralight']?['identifier'] ??
                                         tag.data['nfcv']?['identifier'] ?? [];
            
            if (identifier.isEmpty) {
              _closeAndShowError("Không thể đọc ID thẻ.");
              return;
            }

            final String nfcSerial = identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
            await NfcManager.instance.stopSession();
            
            if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Close bottom sheet

            final result = await _apiService.loginNfc(nfcSerial);
            
            if (mounted) {
              _showLoginSuccess(result['message'], result['user']);
            }
          } catch (e) {
            _closeAndShowError("Lỗi: $e");
          }
        },
        onError: (error) async {
          _closeAndShowError("Lỗi quét: $error");
        },
      );
    } catch (e) {
      // Fallback for Web/Desktop where nfc_manager is not supported
      _showManualNfcDialog();
    }
  }

  void _showManualNfcDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Nhập NFC Serial"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Ví dụ: 04:A1:B2:C3:D4:E5:F6",
            labelText: "NFC Serial Code",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final String code = controller.text.trim();
              if (code.isEmpty) return;
              
              Navigator.pop(dialogContext); // Close dialog
              
              try {
                final result = await _apiService.loginNfc(code);
                if (!mounted) return;
                _showLoginSuccess(result['message'], result['user']);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  void _closeAndShowError(String message) {
    if (!mounted) return;
    if (Navigator.canPop(context)) Navigator.pop(context);
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  void _showScanningBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/books_open.json', width: 150, height: 150),
            const SizedBox(height: 20),
            const Text("Sẵn sàng quét", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF80A1BA))),
            const SizedBox(height: 10),
            const Text("Hãy đưa thẻ NFC lại gần mặt lưng điện thoại", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () {
                NfcManager.instance.stopSession();
                Navigator.pop(context);
              },
              child: const Text("Hủy bỏ", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginSuccess(String message, Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_outline, color: Color(0xFF91C4C3), size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("Mã SV: ${user['user_code']}", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF91C4C3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(userData: user)
                  )
                );
              },
              child: const Text("VÀO TRANG CHỦ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}