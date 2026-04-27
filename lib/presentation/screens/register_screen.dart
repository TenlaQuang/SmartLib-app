import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
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
  
  bool _isPaymentLinkCreated = false;
  int? _payosOrderCode;
  Uint8List? _invoiceImageBytes;
  String? _invoiceFilename;

  Future<void> _createPaymentLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.createPaymentLink(_userCodeController.text.trim());
      final checkoutUrl = data['checkoutUrl'] as String?;
      final orderCode = data['order_code'] as int?;

      if (!mounted) return;

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        setState(() {
          _isPaymentLinkCreated = true;
          _payosOrderCode = orderCode;
        });

        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Không nhận được URL thanh toán');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickInvoiceImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _invoiceImageBytes = bytes;
        _invoiceFilename = pickedFile.name;
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (_invoiceImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải lên ảnh minh chứng thanh toán!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload image first
      final imageUrl = await _apiService.uploadInvoiceImage(_invoiceImageBytes!, _invoiceFilename ?? 'invoice.jpg');

      // 2. Submit form
      final userData = {
        'user_code': _userCodeController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'gender': _gender,
        'birth_year': int.tryParse(_birthYearController.text.trim()),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'invoice_image_url': imageUrl,
        'payos_order_code': _payosOrderCode,
      };

      final success = await _apiService.registerUser(userData);

      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Đăng ký thành công', style: TextStyle(color: Color(0xFF91C4C3))),
            content: const Text('Thông tin của bạn đã được gửi. Vui lòng chờ thư viện phê duyệt.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Về màn hình trước
                },
                child: const Text('Đóng'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.redAccent),
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
                
                if (_isPaymentLinkCreated) ...[
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF91C4C3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Bước 2: Tải lên minh chứng',
                          style: TextStyle(color: Color(0xFF80A1BA), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sau khi thanh toán bên PayOS thành công, vui lòng tải ảnh chụp màn hình bill chuyển khoản lên đây.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        _invoiceImageBytes != null
                            ? Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _invoiceImageBytes!,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _pickInvoiceImage,
                                    icon: const Icon(Icons.edit, color: Color(0xFF91C4C3)),
                                    label: const Text('Chọn ảnh khác', style: TextStyle(color: Color(0xFF91C4C3))),
                                  )
                                ],
                              )
                            : OutlinedButton.icon(
                                onPressed: _pickInvoiceImage,
                                icon: const Icon(Icons.upload_file, color: Color(0xFF91C4C3)),
                                label: const Text('Chọn ảnh Bill', style: TextStyle(color: Color(0xFF91C4C3))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF91C4C3)),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF91C4C3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('HOÀN TẤT ĐĂNG KÝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createPaymentLink,
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
                            'TIẾP TỤC THANH TOÁN',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ]
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
