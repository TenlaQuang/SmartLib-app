import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../data/models/book.dart';

class ApiService {
  // Thay đổi URL tùy thuộc vào môi trường chạy.
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

  Future<Map<String, dynamic>> createPaymentLink(String userCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/create-payment-link'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_code': userCode}),
      ).timeout(const Duration(seconds: 30));

      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return responseData; // { "order_code": ..., "checkoutUrl": ... }
      } else {
        throw Exception(responseData['detail'] ?? 'Tạo link thanh toán thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới Server: $e');
    }
  }

  Future<String?> uploadInvoiceImage(Uint8List imageBytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload-image'));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        )
      );
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return responseData['image_url'];
      } else {
        throw Exception(responseData['detail'] ?? 'Upload ảnh thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  Future<bool> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      ).timeout(const Duration(seconds: 60));

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(responseData['detail'] ?? 'Đăng ký thất bại');
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('TimeoutException')) {
        throw Exception('Server đang khởi động, vui lòng thử lại sau 30 giây...');
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }
}

