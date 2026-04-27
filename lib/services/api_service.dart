import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/book.dart';

class ApiService {
  // Thay đổi URL tùy thuộc vào môi trường chạy.
  // Dùng 10.0.2.2 cho Android Emulator, hoặc 127.0.0.1 cho iOS Simulator / Windows web.
  static const String baseUrl = 'https://smartlib-be.onrender.com';

  Future<List<Book>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/books'));
      
      if (response.statusCode == 200) {
        // Decode body chú ý UTF-8 để hiển thị Tiếng Việt tốt
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books from API');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới Server: $e');
    }
  }

  Future<bool> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Parse the error detail if available
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['detail'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
