import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../data/models/book.dart';

class ApiService {
  // Thay đổi URL tùy thuộc vào môi trường chạy.
  static const String baseUrl = 'https://smartlib-be.onrender.com';

  Future<List<Book>> fetchBooks({String? search}) async {
    try {
      String url = '$baseUrl/api/books?page_size=100';
      if (search != null && search.isNotEmpty) {
        url += '&q=$search';
      }
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books from API');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới Server: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategoriesWithBooks() async {
    try {
      final catResponse = await http.get(Uri.parse('$baseUrl/api/categories')).timeout(const Duration(seconds: 15));
      if (catResponse.statusCode != 200) return [];
      
      List<dynamic> catData = json.decode(utf8.decode(catResponse.bodyBytes));
      // Lấy 5 category đầu tiên
      final topCategories = catData.take(5).toList();
      
      List<Map<String, dynamic>> result = [];
      
      for (var cat in topCategories) {
        final catId = cat['category_id'];
        final catName = cat['name'] ?? 'Thể loại khác';
        
        // Fetch 5 books for this category
        final booksResponse = await http.get(Uri.parse('$baseUrl/api/books?category_id=$catId&page_size=5')).timeout(const Duration(seconds: 10));
        if (booksResponse.statusCode == 200) {
          final Map<String, dynamic> booksResult = json.decode(utf8.decode(booksResponse.bodyBytes));
          final List<dynamic> booksData = booksResult['data'] ?? [];
          final books = booksData.map((json) => Book.fromJson(json)).toList();
          
          if (books.isNotEmpty) {
            result.add({
              'category_id': catId,
              'category_name': catName.toString(),
              'books': books
            });
          }
        }
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  Future<List<Book>> fetchFeaturedWeeklyBooks() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/books/featured-weekly'))
          .timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
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

  Future<bool> registerUser(Map<String, dynamic> userData, Uint8List? imageBytes, String? imageFilename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/register'));
      
      // Thêm các trường form
      userData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Thêm file ảnh nếu có
      if (imageBytes != null && imageFilename != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'invoice_image',
            imageBytes,
            filename: imageFilename,
          )
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      
      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(responseData['detail'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<Map<String, dynamic>> checkUserStatus(String userCode) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/users/check/$userCode'))
          .timeout(const Duration(seconds: 30));
      
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['detail'] ?? 'Kiểm tra mã sinh viên thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<bool> assignNfc(int userId, String nfcSerial) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/assign-nfc'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nfc_serial': nfcSerial}),
      ).timeout(const Duration(seconds: 30));

      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(responseData['detail'] ?? 'Gán thẻ NFC thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<Map<String, dynamic>> loginNfc(String nfcSerial) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login-nfc'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nfc_serial': nfcSerial}),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['detail'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserActivity(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/activity'),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['detail'] ?? 'Không thể lấy dữ liệu hoạt động');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/locations'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Không thể lấy danh sách kệ sách');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchShelfDetails(String shelfId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/shelves/$shelfId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Không thể lấy chi tiết kệ sách');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}

