import 'package:flutter/material.dart';
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

  Future<void> _simulateNfcScan() async {
    if (_userData == null) return;

    setState(() => _isLoading = true);
    try {
      final nfcSerial = "NFC-${DateTime.now().millisecondsSinceEpoch}";
      final success = await _apiService.assignNfc(_userData!['user_id'], nfcSerial);
      if (success) {
        if (mounted) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Thành công"),
          ],
        ),
        content: const Text("Thẻ NFC của bạn đã được kích hoạt thành công. Bạn có thể sử dụng các dịch vụ của thư viện ngay bây giờ."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            child: const Text("Vào trang chủ", style: TextStyle(color: Color(0xFF91C4C3), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            if (_errorMessage != null && _userData?['status'] != 'pending_nfc') ...[
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
            onPressed: _isLoading ? null : _simulateNfcScan,
            icon: const Icon(Icons.nfc_rounded, size: 28),
            label: const Text("QUÉT THẺ NFC", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
