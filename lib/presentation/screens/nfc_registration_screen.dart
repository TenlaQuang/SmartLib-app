import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class NfcRegistrationScreen extends StatefulWidget {
  const NfcRegistrationScreen({super.key});

  @override
  State<NfcRegistrationScreen> createState() => _NfcRegistrationScreenState();
}

class _NfcRegistrationScreenState extends State<NfcRegistrationScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _studentIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  bool _isNfcScanning = false;
  bool _isBottomSheetOpen = false;

  void _safeCloseBottomSheet() {
    if (_isBottomSheetOpen && mounted) {
      Navigator.pop(context);
      _isBottomSheetOpen = false;
    }
  }

  Future<void> _checkStudentId() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) {
      setState(() => _errorMessage = "Vui lòng nhập mã sinh viên");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _userData = null;
    });

    try {
      final result = await _apiService.checkUserStatus(studentId);
      setState(() {
        _userData = result;
        if (result['status'] == 'pending_nfc') {
          _isNfcScanning = true;
          // Tự động bắt đầu quét NFC sau khi xác nhận thông tin thành công
          Future.delayed(const Duration(milliseconds: 500), () => _startNfcScan());
        } else {
          _errorMessage = result['message'];
        }
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startNfcScan() async {
    if (_userData == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check availability
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        _errorMessage = "Thiết bị của bạn không hỗ trợ NFC hoặc chưa được bật.";
        _isLoading = false;
      });
      return;
    }

    _showScanningBottomSheet();

    try {
      // Start Session
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            await HapticFeedback.heavyImpact();
            
            // Extract identifier
            final List<int> identifier = tag.data['isodep']?['identifier'] ?? 
                                         tag.data['nfca']?['identifier'] ?? 
                                         tag.data['mifareultralight']?['identifier'] ??
                                         tag.data['nfcv']?['identifier'] ??
                                         [];
            
            if (identifier.isEmpty) {
               _safeCloseBottomSheet();
               setState(() => _errorMessage = "Không thể đọc được ID của thẻ này.");
               await NfcManager.instance.stopSession();
               setState(() => _isLoading = false);
               return;
            }

            final String nfcSerial = identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
            
            // Stop session immediately after reading
            await NfcManager.instance.stopSession();

            // Close bottom sheet
            _safeCloseBottomSheet();

            final success = await _apiService.assignNfc(_userData!['user_id'], nfcSerial);
            if (success) {
              try {
                // Tự động đăng nhập để lấy thông tin userData đầy đủ
                final loginResult = await _apiService.loginNfc(nfcSerial);
                if (mounted) {
                  _showSuccessDialog(loginResult['user']);
                }
              } catch (e) {
                // Fallback nếu login fail thì vẫn mở dialog với user_id cơ bản
                if (mounted) {
                  _showSuccessDialog({
                    'user_id': _userData!['user_id'],
                    'full_name': _userData!['full_name'],
                  });
                }
              }
            }
          } catch (e) {
            _safeCloseBottomSheet();
            final cleanMessage = e.toString().replaceFirst("Exception: ", "");
            setState(() => _errorMessage = cleanMessage);
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        onError: (error) async {
          _safeCloseBottomSheet();
          setState(() {
            _errorMessage = "Lỗi quét NFC: $error";
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      _safeCloseBottomSheet();
      setState(() {
        _errorMessage = "Không thể khởi động trình quét NFC: $e";
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic> user) {
    // Lưu phiên đăng nhập tự động
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user_session', json.encode(user));
    }).catchError((e) {
      debugPrint("Lỗi lưu phiên đăng nhập: $e");
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF91C4C3), Color(0xFF80A1BA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 80),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          "KÍCH HOẠT THÀNH CÔNG!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF80A1BA),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Thẻ SmartLib của bạn đã sẵn sàng để sử dụng. Chào mừng bạn đến với thư viện thông minh!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => HomeScreen(userData: user)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF91C4C3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: const Text("VÀO TRANG CHỦ", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showScanningBottomSheet() {
    _isBottomSheetOpen = true;
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(32),
              height: 400,
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
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF80A1BA)),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Hãy áp thẻ của bạn vào mặt lưng điện thoại",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const Spacer(),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF91C4C3).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(Icons.contactless_rounded, color: Color(0xFF91C4C3), size: 60),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _safeCloseBottomSheet();
                    },
                    child: const Text("Hủy bỏ", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _isBottomSheetOpen = false;
      // Ensure session is stopped if user dismisses bottom sheet
      NfcManager.instance.stopSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF80A1BA)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Đăng ký thẻ SmartLib",
          style: TextStyle(color: Color(0xFF80A1BA), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            _buildInfoCard(),
            const SizedBox(height: 30),
            if (!_isNfcScanning) ...[
              _buildInputSection(),
            ] else ...[
              _buildNfcScanningSection(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              _buildErrorSection(),
            ],
            const SizedBox(height: 40),
            _buildRegistrationPrompt(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_user_rounded, color: Color(0xFF91C4C3), size: 48),
          SizedBox(height: 15),
          Text(
            "Xác nhận thông tin",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF80A1BA)),
          ),
          SizedBox(height: 10),
          Text(
            "Nhập mã sinh viên để kiểm tra trạng thái phê duyệt của thư viện trước khi kích hoạt thẻ vật lý.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _studentIdController,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF80A1BA)),
            decoration: InputDecoration(
              labelText: "Mã sinh viên",
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: "VD: 20110xxx",
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF91C4C3)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _checkStudentId,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF91C4C3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              shadowColor: const Color(0xFF91C4C3).withOpacity(0.4),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                : const Text("Kiểm tra ngay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildNfcScanningSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFB4DEBD).withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFB4DEBD), width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.contactless_rounded, color: Color(0xFF91C4C3), size: 80),
              const SizedBox(height: 20),
              Text(
                "Xin chào, ${_userData?['full_name']}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF80A1BA)),
              ),
              const SizedBox(height: 12),
              const Text(
                "Thông tin của bạn đã được duyệt thành công.\nVui lòng áp thẻ NFC vào mặt sau điện thoại để hoàn tất kích hoạt.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _startNfcScan,
            icon: const Icon(Icons.nfc_rounded, size: 28),
            label: const Text("BẮT ĐẦU QUÉT LẠI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF80A1BA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _isNfcScanning = false;
              _userData = null;
              _errorMessage = null;
            });
          },
          child: const Text("Nhập mã sinh viên khác", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? "Thông tin không hợp lệ",
              style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationPrompt() {
    return Column(
      children: [
        const Text("Bạn là sinh viên mới?", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB4DEBD), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text(
              "ĐĂNG KÝ THÔNG TIN NGAY",
              style: TextStyle(color: Color(0xFF80A1BA), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
