import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ShelfDetailScreen extends StatefulWidget {
  final String shelfId;
  const ShelfDetailScreen({super.key, required this.shelfId});

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
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA67C52), Color(0xFF8B5E3C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), offset: const Offset(0, 6), blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(height: 2), // Độ dày cạnh kệ
              ],
            ),
            
            // Sách xếp đứng trên kệ
            Padding(
              padding: const EdgeInsets.only(bottom: 18, left: 25, right: 25),
              child: SizedBox(
                height: 110,
                child: books.isEmpty 
                  ? const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text("Trống", style: TextStyle(color: Colors.brown, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: books.length,
                      itemBuilder: (context, bIndex) {
                        final book = books[bIndex];
                        return _buildBookItem(book);
                      },
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 50), // Khoảng cách giữa các hàng kệ
      ],
    );
  }

  Widget _buildBookItem(dynamic book) {
    return Container(
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
          Image.network(
            (book['image_url'] != null && book['image_url'] != "") 
                ? book['image_url'] 
                : 'https://covers.openlibrary.org/b/isbn/${book['isbn']}-M.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.blueGrey[100],
              padding: const EdgeInsets.all(4),
              child: Center(
                child: Text(
                  book['title'], 
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center,
                  maxLines: 4,
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
    );
  }
}
