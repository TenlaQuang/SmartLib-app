import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  final TextEditingController _userCodeController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String _gender = 'Nam';

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userData = {
      'user_code': _userCodeController.text.trim(),
      'full_name': _fullNameController.text.trim(),
      'gender': _gender,
      'birth_year': int.tryParse(_birthYearController.text.trim()),
      'phone_number': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'email': _emailController.text.trim(),
    };

    try {
      final checkoutUrl = await _apiService.registerUser(userData);

      if (!mounted) return;

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        // Mở trang thanh toán PayOS trong trình duyệt
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        // Hiện dialog thông báo sau khi mở thanh toán
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.payment_rounded, color: Color(0xFF91C4C3), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Thanh toán',
                    style: TextStyle(
                      color: Color(0xFF80A1BA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trang thanh toán PayOS đã được mở trên trình duyệt.',
                    style: TextStyle(color: Color(0xFF80A1BA), fontSize: 15),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '✅ Vui lòng quét mã QR và hoàn tất chuyển khoản.',
                    style: TextStyle(color: Color(0xFF91C4C3), fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '📩 Sau khi thanh toán, hãy chờ email xác nhận phê duyệt từ thư viện.',
                    style: TextStyle(color: Color(0xFF91C4C3), fontSize: 14),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    Navigator.of(context).pop(); // Quay về trang Intro
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB4DEBD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Đã hiểu, quay về',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        // Không có checkout URL - đăng ký thành công nhưng không có link thanh toán
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Đang chờ phê duyệt.'),
            backgroundColor: Color(0xFF91C4C3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD), // Nền kem sáng
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản', style: TextStyle(color: Color(0xFF80A1BA), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF80A1BA)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SMARTLIB',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF80A1BA),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vui lòng nhập thông tin để đăng ký mượn sách',
                  style: TextStyle(color: Color(0xFF91C4C3), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Form fields
                _buildTextField(
                  controller: _userCodeController,
                  label: 'Mã SV / CCCD (*)',
                  icon: Icons.badge_outlined,
                  validator: (value) => value!.isEmpty ? 'Vui lòng nhập Mã SV/CCCD' : null,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Họ và tên (*)',
                  icon: Icons.person_outline,
                  validator: (value) => value!.isEmpty ? 'Vui lòng nhập Họ và tên' : null,
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                    labelStyle: const TextStyle(color: Color(0xFF91C4C3)),
                    prefixIcon: const Icon(Icons.wc_outlined, color: Color(0xFF91C4C3)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF91C4C3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF91C4C3), width: 1.5),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF80A1BA), fontSize: 16),
                  items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _gender = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 15),
                
                _buildTextField(
                  controller: _birthYearController,
                  label: 'Năm sinh',
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB4DEBD),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                    shadowColor: const Color(0xFFB4DEBD).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'GỬI ĐĂNG KÝ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFF80A1BA), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF91C4C3)),
        prefixIcon: Icon(icon, color: const Color(0xFF91C4C3)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF91C4C3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF91C4C3), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _userCodeController.dispose();
    _fullNameController.dispose();
    _birthYearController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
