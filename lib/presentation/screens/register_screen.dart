import 'package:flutter/material.dart';
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

    setState(() {
      _isLoading = true;
    });

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
      final success = await _apiService.registerUser(userData);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Yêu cầu của bạn đang chờ duyệt.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Trở về trang trước
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vui lòng nhập thông tin để đăng ký mượn sách',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
                
                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.wc_outlined, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
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
                    backgroundColor: Colors.greenAccent[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
