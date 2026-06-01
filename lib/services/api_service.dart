import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../data/models/book.dart';

class ApiService {
  // Thay đổi URL tùy thuộc vào môi trường chạy.
  static const String baseUrl = 'https://smartlib-be.onrender.com';

  // Biến static để đảm bảo chỉ có 1 timer chạy
  static Timer? _keepAliveTimer;

  /// Bắt đầu gửi tín hiệu "đánh thức" server định kỳ (mỗi 10 phút)
  /// vì Render gói free sẽ tự ngủ sau 15 phút không hoạt động.
  void startKeepAliveTimer() {
    if (_keepAliveTimer != null) return;
    
    print("--- Khởi động Keep-Alive Timer cho Render ---");
    // Chạy lần đầu ngay lập tức
    _pingServer();

    // Thiết lập chạy định kỳ mỗi 10 phút
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _pingServer();
    });
  }

  Future<void> _pingServer() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        print("--- Render Keep-Alive: Success ---");
      }
    } catch (e) {
      print("--- Render Keep-Alive Error: $e ---");
    }
  }

  Future<List<Book>> fetchBooks({String? search}) async {
    try {
      String url = '$baseUrl/api/books?page_size=100';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
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

  Future<List<Book>> fetchUserRecommendations(int userId) async {
    try {
      final url = '$baseUrl/api/recommendations/user-centric/$userId';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Lỗi fetchUserRecommendations: $e");
      return [];
    }
  }

  Future<int?> createBorrowRequest(int userId, List<String> isbns) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/borrow-requests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'isbns': isbns,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['request_id'];
      } else {
        throw Exception('Failed to create borrow request: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới Server: $e');
    }
  }

  Future<String> getBorrowRequestStatus(int requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/borrow-requests/$requestId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['status']; // 'pending', 'approved', 'rejected'
      }
      return 'pending';
    } catch (e) {
      return 'pending';
    }
  }

  Future<int?> createReturnRequest(int userId, List<String> isbns) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/return-requests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'isbns': isbns,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['request_id'];
      } else {
        throw Exception('Failed to create return request: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới Server: $e');
    }
  }

  Future<String> getReturnRequestStatus(int requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/return-requests/$requestId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['status']; // 'pending', 'approved', 'rejected'
      }
      return 'pending';
    } catch (e) {
      return 'pending';
    }
  }

  Future<List<Book>> getRelatedBooks(int bookId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/books/$bookId/related'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Book.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching related books: $e');
      return [];
    }
  }

  // --- Comment APIs ---
  Future<List<Map<String, dynamic>>> fetchBookComments(int bookId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/books/$bookId/comments')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(utf8.decode(response.bodyBytes)));
      }
      return [];
    } catch (e) {
      print("Error fetching comments: $e");
      return [];
    }
  }

  Future<bool> postComment(int userId, int bookId, String content, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'book_id': bookId,
          'content': content,
          'rating': rating,
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Error posting comment: $e");
      return false;
    }
  }

  // --- Favorite APIs ---
  Future<bool> toggleFavorite(int userId, int bookId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/favorites/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'book_id': bookId,
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Error toggling favorite: $e");
      return false;
    }
  }

  Future<bool> checkIsFavorite(int userId, int bookId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/users/$userId/favorites/$bookId')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['is_favorite'] ?? false;
      }
      return false;
    } catch (e) {
      print("Error checking favorite: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategoriesWithBooks() async {
    try {
      final catResponse = await http.get(Uri.parse('$baseUrl/api/categories')).timeout(const Duration(seconds: 15));
      if (catResponse.statusCode != 200) return [];
      
      List<dynamic> catData = json.decode(utf8.decode(catResponse.bodyBytes));
      // Lấy 5 category đầu tiên
      final topCategories = catData.take(5).toList();
      
      // Khởi tạo List các Future để gọi song song
      List<Future<Map<String, dynamic>?>> fetchFutures = topCategories.map((cat) async {
        final catId = cat['category_id'];
        final catName = cat['name'] ?? 'Thể loại khác';
        
        try {
          final booksResponse = await http.get(Uri.parse('$baseUrl/api/books?category_id=$catId&page_size=5')).timeout(const Duration(seconds: 10));
          if (booksResponse.statusCode == 200) {
            final Map<String, dynamic> booksResult = json.decode(utf8.decode(booksResponse.bodyBytes));
            final List<dynamic> booksData = booksResult['data'] ?? [];
            final books = booksData.map((json) => Book.fromJson(json)).toList();
            
            if (books.isNotEmpty) {
              return {
                'category_id': catId,
                'category_name': catName.toString(),
                'books': books
              };
            }
          }
        } catch (_) {}
        return null;
      }).toList();

      final results = await Future.wait(fetchFutures);
      
      return results.whereType<Map<String, dynamic>>().toList();
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

  Future<Map<String, dynamic>> updateUserSecure({
    required int userId,
    required String email,
    required String phoneNumber,
    required String nfcSerial,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId/update-secure'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'phone_number': phoneNumber,
          'nfc_serial': nfcSerial,
        }),
      ).timeout(const Duration(seconds: 15));

      final responseData = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message'] ?? 'Thành công!'};
      } else {
        return {'success': false, 'message': responseData['detail'] ?? 'Cập nhật thất bại!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Notification APIs ---
  Future<List<Map<String, dynamic>>> fetchUserNotifications(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print("Lỗi fetchUserNotifications: $e");
      return [];
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi markNotificationAsRead: $e");
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/user/$userId/read-all'),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi markAllNotificationsAsRead: $e");
      return false;
    }
  }

  Future<bool> checkOngoingBorrow(int userId, String isbn) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/check-ongoing-borrow/$isbn'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['is_borrowed'] ?? false;
      }
      return false;
    } catch (e) {
      print("Lỗi checkOngoingBorrow: $e");
      return false;
    }
  }
}


