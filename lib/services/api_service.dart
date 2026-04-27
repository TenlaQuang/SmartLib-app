import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/book.dart';

class ApiService {
  // Thay đổi URL tùy thuộc vào môi trường chạy.
  // Dùng 10.0.2.2 cho Android Emulator, hoặc 127.0.0.1 cho iOS Simulator / Windows web.
  static const String baseUrl = 'https://smartlib-be.onrender.com';

  Future<List<Book>> fetchBooks() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/books'))
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books from API');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới Server: $e');
    }
  }

  Future<String?> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      ).timeout(const Duration(seconds: 60)); // Timeout dài hơn vì PayOS cần thời gian

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return responseData['checkoutUrl'] as String?;
      } else {
        throw Exception(responseData['detail'] ?? 'Đăng ký thất bại');
      }
    } on Exception catch (e) {
      // Bắt riêng TimeoutException để thông báo rõ hơn
      final msg = e.toString();
      if (msg.contains('TimeoutException')) {
        throw Exception('Server đang khởi động, vui lòng thử lại sau 30 giây...');
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
