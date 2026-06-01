import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _checkSessionPersistence();
  }

  Future<void> _checkSessionPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> user = json.decode(sessionStr);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userData: user)),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải phiên đăng nhập: $e");
    } finally {
      if (mounted) {
        setState(() {
          _checkingSession = false;
        });
      }
    }
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
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF7DD),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF91C4C3),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD),
      resizeToAvoidBottomInset: false, // Ngăn chặn sọc vàng khi bàn phím hiện lên
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
                      
                      const SizedBox(height: 350), 


                      


                      
                      Opacity(
                        opacity: uiOpacity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Transform.translate(
                                offset: Offset(-spreadOffset, 0),
                                child: _buildActionButton(
                                  title: "QUÉT THẺ NFC",
                                  icon: Icons.nfc_rounded,
                                  color: const Color(0xFF80A1BA), // Sử dụng màu xanh chủ đạo cho NFC
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Thiết bị chưa bật NFC hoặc không hỗ trợ. Đang chuyển sang nhập tay..."),
              backgroundColor: Colors.orangeAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        height: 420,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Sẵn sàng quét thẻ",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF80A1BA),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Hãy áp thẻ SmartLib của bạn vào mặt lưng điện thoại để đăng nhập",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
            ),
            const Spacer(),
            // Hiệu ứng quét thẻ NFC
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF80A1BA).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                Lottie.asset(
                  'assets/animations/books_open.json', // Có thể thay bằng animation sóng NFC nếu có
                  width: 180,
                  height: 180,
                ),
                const Icon(Icons.contactless_rounded, color: Color(0xFF80A1BA), size: 50),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  NfcManager.instance.stopSession();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Hủy bỏ",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      NfcManager.instance.stopSession();
    });
  }

  void _showLoginSuccess(String message, Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', json.encode(user));
    } catch (e) {
      debugPrint("Lỗi lưu phiên đăng nhập: $e");
    }

    if (!mounted) return;
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