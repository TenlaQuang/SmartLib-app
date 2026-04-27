import 'package:flutter/material.dart';
import '../../data/models/book.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Book>> _booksFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _booksFuture = _apiService.fetchBooks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A708B), // Màu theo mẫu
        elevation: 0,
        title: const Text(
          "Library",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.view_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white, // Indicator màu trắng như mẫu
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF4A708B),
              unselectedLabelColor: Colors.white,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: const [
                Tab(text: "Shelves"),
                Tab(text: "Books"),
                Tab(text: "Lend/Borrow"),
                Tab(text: "WishList"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShelvesTab(),
          _buildBooksTab(),
          const Center(child: Text("Lịch sử Mượn/Trả", style: TextStyle(color: Colors.grey))),
          const Center(child: Text("Danh sách mong muốn", style: TextStyle(color: Colors.grey))),
        ],
      ),
      // Nút quét QR mượn sách AI duy nhất ở dưới cùng
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            )
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Mở Camera quét QR mượn sách
            },
            icon: const Icon(Icons.qr_code_scanner, size: 24),
            label: const Text(
              "Quét QR Mượn Sách (AI)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A708B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Tab 1: Shelves (Khám phá theo Kệ) ---
  Widget _buildShelvesTab() {
    return Column(
      children: [
        // Thanh Breadcrumb "Home >" và số lượng "15/3099"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.home, size: 20, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(">", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: const [
                  Text("15/3099", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  SizedBox(width: 8),
                  Icon(Icons.filter_list, color: Colors.grey),
                ],
              )
            ],
          ),
        ),
        const Divider(height: 1),
        // Lưới hiển thị các kệ sách tĩnh
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
              childAspectRatio: 0.65, // Tỷ lệ để nhét vừa ảnh dọc
            ),
            itemCount: 12, // Hiển thị mẫu 12 kệ
            itemBuilder: (context, index) {
              final shelfName = String.fromCharCode(65 + index); // A, B, C...
              return _buildShelfItem("Shelf $shelfName", (index + 1) * 7 + 3);
            },
          ),
        ),
      ],
    );
  }

  // Widget mô phỏng 1 Kệ sách (Hình xếp chồng sách)
  Widget _buildShelfItem(String shelfName, int bookCount) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Cột sách xếp chồng
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Cuốn 1 (Dưới cùng)
                    Positioned(
                      bottom: 12,
                      child: Container(
                        width: 55,
                        height: 75,
                        decoration: BoxDecoration(
                          color: Colors.red[300],
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2))],
                        ),
                      ),
                    ),
                    // Cuốn 2 (Giữ)
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: 60,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange[300],
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2))],
                        ),
                      ),
                    ),
                    // Cuốn 3 (Trên cùng)
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 65,
                        height: 85,
                        decoration: BoxDecoration(
                          color: Colors.blue[800],
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        // Thêm 1 icon biểu tượng cuốn sách
                        child: const Center(
                          child: Icon(Icons.import_contacts_rounded, color: Colors.white54, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Nhãn xoay dọc: "33 books"
              RotatedBox(
                quarterTurns: 3, // Quay 270 độ
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    "$bookCount books",
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Nền chữ Shelf A
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4A708B),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            shelfName,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  // --- Tab 2: Books (Hiển thị API thực tế như cũ) ---
  Widget _buildBooksTab() {
    return FutureBuilder<List<Book>>(
      future: _booksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4A708B)));
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
                const SizedBox(height: 15),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _booksFuture = _apiService.fetchBooks();
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A708B)),
                  child: const Text("Thử lại"),
                )
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Không có sách nào.", style: TextStyle(color: Colors.black54)),
          );
        }

        final books = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 20,
            childAspectRatio: 0.65,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return _buildBookCard(book);
          },
        );
      },
    );
  }

  // Card hiển thị sách như cũ nhưng đổi sang tông sáng phù hợp với theme mới
  Widget _buildBookCard(Book book) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh bìa
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.network(
                (book.imageUrl != null && book.imageUrl!.isNotEmpty)
                    ? book.imageUrl!
                    : (book.isbn.isNotEmpty 
                        ? 'https://covers.openlibrary.org/b/isbn/${book.isbn}-L.jpg' 
                        : ''),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.grey,
                  size: 50,
                ),
              ),
            ),
          ),
          // Thông tin sách
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  book.categoryName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (book.status.toLowerCase() == "có sẵn" || book.status.toLowerCase() == "available")
                        ? Colors.green.withOpacity(0.15) 
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (book.status.toLowerCase() == "có sẵn" || book.status.toLowerCase() == "available") ? "Có sẵn" : book.status,
                    style: TextStyle(
                      color: (book.status.toLowerCase() == "có sẵn" || book.status.toLowerCase() == "available")
                          ? Colors.green[700] 
                          : Colors.orange[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
