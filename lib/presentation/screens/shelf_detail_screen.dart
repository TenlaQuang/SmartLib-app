import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../data/models/book.dart';
import 'book_detail_screen.dart';

class ShelfDetailScreen extends StatefulWidget {
  final String shelfId;
  final Map<String, dynamic>? userData;
  const ShelfDetailScreen({super.key, required this.shelfId, this.userData});

  @override
  State<ShelfDetailScreen> createState() => _ShelfDetailScreenState();
}

class _ShelfDetailScreenState extends State<ShelfDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _shelfDetailsFuture;

  @override
  void initState() {
    super.initState();
    _shelfDetailsFuture = _apiService.fetchShelfDetails(widget.shelfId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE49E), // Màu kem vàng đặc trưng của thư viện
      appBar: AppBar(
        title: Text("Kệ ${widget.shelfId}"),
        backgroundColor: const Color(0xFF80A1BA),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _shelfDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF80A1BA)));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text("Lỗi: ${snapshot.error}"),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Kệ này chưa có thông tin hàng sách."));
          }

          final levels = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 30),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              return _buildShelfRow(
                "HÀNG ${level['level_number']}",
                level['books'] as List<dynamic>,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShelfRow(String label, List<dynamic> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nhãn Hàng (Giống bản Web)
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF5D3A1A), // Nâu gỗ đậm cho nhãn
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)
              ]
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        
        // Sách và Thanh Kệ 3D
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Thanh gỗ kệ sách (Có chiều sâu)
            Column(
              children: [
                const SizedBox(height: 100), // Khoảng trống cho sách đứng
                Container(
                  height: 12,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5A2B),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), offset: const Offset(0, 4), blurRadius: 6)
                    ]
                  ),
                ),
              ],
            ),
            
            // Danh sách sách (Nằm trên thanh gỗ)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                itemBuilder: (context, idx) => _buildBookItem(books[idx]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBookItem(dynamic bookData) {
    // Chuyển đổi dữ liệu từ Map sang model Book
    final book = Book.fromJson(bookData);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => BookDetailScreen(book: book, userData: widget.userData),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(3, 0), blurRadius: 3)
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Hero(
              tag: 'book_cover_${book.id}',
              child: Image.network(
                (bookData['image_url'] != null && bookData['image_url'] != "") 
                    ? bookData['image_url'] 
                    : 'https://covers.openlibrary.org/b/isbn/${bookData['isbn']}-M.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.blueGrey[100],
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(
                      bookData['title'] ?? 'N/A', 
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.center,
                      maxLines: 4,
                    ),
                  ),
                ),
              ),
            ),
            // Hiệu ứng bóng gáy sách
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.2), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
