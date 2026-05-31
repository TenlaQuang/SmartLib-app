import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../data/models/book.dart';
import '../../services/api_service.dart';
import '../screens/book_detail_screen.dart' hide optimizeCloudinaryUrl;
import '../screens/home_screen.dart';

class ExplorePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ExplorePage({super.key, this.userData});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<Book>> _randomBooksFuture;
  Future<List<Book>>? _searchResultsFuture;
  
  bool _isSearching = false;
  
  List<String> _recentSearches = [
    'Novel',
    'fantasy',
    'Crime',
    'romantic',
    'Fiction'
  ];

  @override
  void initState() {
    super.initState();
    _randomBooksFuture = _fetchRandomAvailableBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Book>> _fetchRandomAvailableBooks() async {
    try {
      final books = await _apiService.fetchBooks();
      // 1. Lọc các cuốn sách có trạng thái "available"
      final availableBooks = books.where((book) => book.status.toLowerCase() == 'available').toList();
      
      // 2. Loại bỏ trùng lặp bản sao đầu sách (chỉ giữ lại 1 cuốn đại diện cho mỗi ISBN hoặc Title)
      final Map<String, Book> uniqueBooksMap = {};
      for (final book in availableBooks) {
        final key = book.isbn.isNotEmpty ? book.isbn : book.title;
        if (!uniqueBooksMap.containsKey(key)) {
          uniqueBooksMap[key] = book;
        }
      }
      
      final uniqueBooksList = uniqueBooksMap.values.toList();
      
      // 3. Lấy ngẫu nhiên vài cuốn không trùng lặp từ danh sách duy nhất
      uniqueBooksList.shuffle(Random());
      return uniqueBooksList.take(12).toList();
    } catch (e) {
      debugPrint("Error fetching random available books: $e");
      return [];
    }
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResultsFuture = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      // Thêm vào danh sách tìm kiếm gần đây nếu chưa có
      final trimmedQuery = query.trim();
      if (!_recentSearches.contains(trimmedQuery)) {
        _recentSearches.insert(0, trimmedQuery);
        if (_recentSearches.length > 8) {
          _recentSearches.removeLast();
        }
      }
      
      // Thực hiện tìm kiếm sách
      _searchResultsFuture = _apiService.fetchBooks(search: trimmedQuery);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResultsFuture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Thanh tìm kiếm cao cấp
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm sách, tác giả, thể loại...",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF80A1BA)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onChanged: (val) {
                    setState(() {}); // cập nhật nút clear
                  },
                ),
              ),
            ),

            // 2. Giao diện thay đổi theo trạng thái tìm kiếm
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildIdleState(),
            ),
          ],
        ),
      ),
    );
  }

  // --- TRẠNG THÁI CHỜ/MẶC ĐỊNH (Theo như ảnh yêu cầu) ---
  Widget _buildIdleState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. PHẦN HIỂN THỊ SÁCH NGẪU NHIÊN CÓ SẴN (available) - Chia 2 hàng sách
          const SizedBox(height: 10),
          FutureBuilder<List<Book>>(
            future: _randomBooksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 250,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF80A1BA)),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final randomBooks = snapshot.data!;
              final row1Books = randomBooks.take(6).toList();
              final row2Books = randomBooks.skip(6).take(6).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng sách thứ nhất
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: row1Books.length,
                      itemBuilder: (context, index) {
                        final book = row1Books[index];
                        return _buildRandomBookCard(book);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Hàng sách thứ hai
                  if (row2Books.isNotEmpty)
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: row2Books.length,
                        itemBuilder: (context, index) {
                          final book = row2Books[index];
                          return _buildRandomBookCard(book);
                        },
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 25),

          // B. PHẦN TÌM KIẾM GẦN ĐÂY (Giống hệt hình ảnh yêu cầu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Searched",
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                if (_recentSearches.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _recentSearches.clear();
                      });
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_recentSearches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Text(
                "Chưa có tìm kiếm gần đây.",
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _recentSearches.map((query) => InkWell(
                  onTap: () {
                    _searchController.text = query;
                    _onSearch(query);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300]!.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      query,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- TRẠNG THÁI KẾT QUẢ TÌM KIẾM ---
  Widget _buildSearchResults() {
    return FutureBuilder<List<Book>>(
      future: _searchResultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF80A1BA)),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text("Đã xảy ra lỗi: ${snapshot.error}"));
        }

        final rawBooks = snapshot.data ?? [];
        if (rawBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  "Không tìm thấy cuốn sách nào phù hợp.",
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        // Nhóm các sách trùng nhau theo ISBN hoặc Tiêu đề (gộp các bản sao)
        final Map<String, List<Book>> grouped = {};
        for (final book in rawBooks) {
          final key = book.isbn.isNotEmpty ? book.isbn : book.title;
          if (!grouped.containsKey(key)) {
            grouped[key] = [];
          }
          grouped[key]!.add(book);
        }

        // Chuyển đổi dữ liệu nhóm thành danh sách duy nhất kèm thống kê số lượng
        final groupedList = grouped.values.map((list) {
          final representative = list.first;
          final availableCount = list.where((b) => b.status.toLowerCase() == 'available').length;
          final totalCount = list.length;
          return {
            'book': representative,
            'available': availableCount,
            'total': totalCount,
          };
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 4.0, bottom: 12.0),
              child: Text(
                "Tìm thấy ${groupedList.length} đầu sách phù hợp",
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: groupedList.length,
                itemBuilder: (context, index) {
                  final item = groupedList[index];
                  final book = item['book'] as Book;
                  final availableCount = item['available'] as int;
                  final totalCount = item['total'] as int;
                  return _buildSearchResultBookCard(book, availableCount, totalCount);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET THẺ SÁCH NGẪU NHIÊN (Khớp thiết kế giao diện ảnh) ---
  Widget _buildRandomBookCard(Book book) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa sách dạng hình chữ nhật đứng bo góc
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                    ? Image.network(
                        optimizeCloudinaryUrl(book.imageUrl!, width: 250),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, e, s) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Tên sách (In đậm nổi bật giống hình)
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 3),
            // Tác giả (Chữ thường, màu nhạt giống hình)
            Text(
              book.author.toLowerCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET THẺ KẾT QUẢ TÌM KIẾM ---
  Widget _buildSearchResultBookCard(Book book, int availableCount, int totalCount) {
    final bool isAvailable = availableCount > 0;

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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ảnh bìa sách với nhãn trạng thái đè lên ở góc dưới bên trái
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                      ? Image.network(
                          optimizeCloudinaryUrl(book.imageUrl!, width: 300),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, e, s) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                ),
                // Nhãn "Có sẵn: X/Y" nằm ở góc dưới bên trái của ảnh
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable 
                          ? const Color(0xFF91C4C3).withOpacity(0.85) 
                          : Colors.orange.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isAvailable ? "Có sẵn: $availableCount/$totalCount" : "Đã mượn hết",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 2. Tên sách (In đậm nổi bật bên dưới ảnh)
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 3),
          // 3. Tác giả (Chữ thường, màu nhạt)
          Text(
            book.author.toLowerCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
