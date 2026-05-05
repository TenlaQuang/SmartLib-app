import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:palette_generator/palette_generator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/book.dart';
import 'shelf_detail_screen.dart';
import '../../services/api_service.dart';
import '../widgets/profile_page.dart';
import '../widgets/scanner_page.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Book>> _weeklyFeaturedFuture;
  late Future<List<Map<String, dynamic>>> _categoriesWithBooksFuture;
  late Future<List<dynamic>> _combinedLibraryFuture;
  int _selectedIndex = 0;

  void _loadData() {
    setState(() {
      _weeklyFeaturedFuture = _apiService.fetchFeaturedWeeklyBooks();
      _categoriesWithBooksFuture = _apiService.fetchCategoriesWithBooks();
      _combinedLibraryFuture = Future.wait([_weeklyFeaturedFuture, _categoriesWithBooksFuture]);
    });
  }

  @override
  void initState() {
    super.initState();
    _weeklyFeaturedFuture = _apiService.fetchFeaturedWeeklyBooks();
    _categoriesWithBooksFuture = _apiService.fetchCategoriesWithBooks();
    _combinedLibraryFuture = Future.wait([_weeklyFeaturedFuture, _categoriesWithBooksFuture]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD),
      appBar: _selectedIndex == 0 
        ? AppBar(
            backgroundColor: const Color(0xFF80A1BA),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "SmartLib Home",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          )
        : null,
      body: _selectedIndex == 0
          ? _buildLibraryView()
          : _selectedIndex == 1
              ? const ScannerPage()
              : ProfilePage(
                  userData: widget.userData ?? {},
                  onLogout: () => Navigator.pop(context),
                ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF80A1BA),
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_rounded),
              label: "Thư viện",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              label: "Quét mã",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "Cá nhân",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryView() {
    return FutureBuilder<List<dynamic>>(
      future: _combinedLibraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(child: CircularProgressIndicator(color: Color(0xFF91C4C3))),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Đang tải dữ liệu..."));
        }

        final data = snapshot.data ?? [];
        if (data.length < 2) return const Center(child: Text("Lỗi dữ liệu"));
        final weeklyBooks = data[0] as List<Book>;
        final categoryGroups = data[1] as List<Map<String, dynamic>>;

        return SingleChildScrollView(
          key: const ValueKey('library_content_scroll_view'),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sách được đọc nhiều nhất trong tuần
              _buildFeaturedSection(weeklyBooks),

              // 2. Có thể bạn sẽ thích
              _buildHorizontalList(
                "Có thể bạn sẽ thích", 
                [],
                icon: Icons.thumb_up_alt_rounded,
                color: Colors.orangeAccent,
              ),

              // 3. Từng tủ sách (Theo Category)
              ...categoryGroups.asMap().entries.map((entry) {
                 final index = entry.key;
                 final group = entry.value;
                 final categoryName = group['category_name'].toString();
                 
                 return _buildHorizontalList(
                   "Khu ${index + 1}", 
                   group['books'] as List<Book>,
                   icon: _getIconForCategory(categoryName),
                   color: _getColorForIndex(index),
                 );
              }),
              
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String categoryName) {
    categoryName = categoryName.toLowerCase();
    if (categoryName.contains('khoa học')) return Icons.science_rounded;
    if (categoryName.contains('công nghệ') || categoryName.contains('it') || categoryName.contains('máy tính')) return Icons.computer_rounded;
    if (categoryName.contains('kinh tế') || categoryName.contains('tài chính')) return Icons.trending_up_rounded;
    if (categoryName.contains('tâm lý')) return Icons.psychology_rounded;
    if (categoryName.contains('văn học') || categoryName.contains('tiểu thuyết')) return Icons.auto_stories_rounded;
    if (categoryName.contains('lịch sử')) return Icons.account_balance_rounded;
    if (categoryName.contains('toán')) return Icons.calculate_rounded;
    if (categoryName.contains('nghệ thuật')) return Icons.palette_rounded;
    if (categoryName.contains('ngôn ngữ')) return Icons.language_rounded;
    return Icons.local_library_rounded; // default
  }

  Color _getColorForIndex(int index) {
    const colors = [
      Color(0xFF80A1BA), // Blue
      Color(0xFFE2B4B4), // Soft Pink
      Color(0xFF91C4C3), // Teal
      Color(0xFFF0D1A8), // Soft Orange
      Color(0xFFB1A1C4), // Soft Purple
      Color(0xFF8BBF88), // Soft Green
    ];
    return colors[index % colors.length];
  }

  Widget _buildFeaturedSection(List<Book> books) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: FeaturedCarousel(books: books),
    );
  }

  Widget _buildHorizontalList(String title, List<Book> books, {IconData? icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (color ?? const Color(0xFF91C4C3)).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color ?? const Color(0xFF91C4C3), size: 24),
                  ),
                  const SizedBox(width: 15),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (books.isEmpty)
            const SizedBox(height: 200)
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: books.length + 1,
                itemBuilder: (context, index) {
                  if (index == books.length) {
                    return _buildSeeMoreButton(title);
                  }
                  return _buildBookCard(books[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeeMoreButton(String categoryName) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 15),
      child: Center(
        child: InkWell(
          onTap: () {
            // TODO: Chuyển hướng đến trang danh mục chi tiết
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF91C4C3)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_forward_rounded, color: Color(0xFF91C4C3), size: 30),
                SizedBox(height: 8),
                Text("Xem thêm", style: TextStyle(color: Color(0xFF80A1BA), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }





  // Card hiển thị sách như cũ nhưng đổi sang tông sáng phù hợp với theme mới
  Widget _buildBookCard(Book book) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15),
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
              child: _buildBookImage(book),
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

  Widget _buildBookImage(Book book) {
    String finalUrl = '';
    if (book.imageUrl != null && book.imageUrl!.isNotEmpty) {
      finalUrl = book.imageUrl!;
    } else if (book.isbn.isNotEmpty) {
      finalUrl = 'https://covers.openlibrary.org/b/isbn/${book.isbn}-L.jpg';
    }

    if (finalUrl.isEmpty) {
      return const Icon(
        Icons.menu_book_rounded,
        color: Colors.grey,
        size: 50,
      );
    }

    return Image.network(
      finalUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.menu_book_rounded,
        color: Colors.grey,
        size: 50,
      ),
    );
  }
}

class FeaturedCarousel extends StatefulWidget {
  final List<Book> books;
  const FeaturedCarousel({super.key, required this.books});

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _sparkleController;
  Timer? _timer;
  
  Color _currentDominantColor = const Color(0xFFF0F4F8); // Màu mặc định
  final Map<int, Color> _colorCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Khởi tạo màu cho cuốn sách đầu tiên
    if (widget.books.isNotEmpty) {
      _extractColor(widget.books.first, 0);
    }
    _sparkleController.forward(from: 0.0);

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (widget.books.isNotEmpty && _pageController.hasClients) {
        int nextIndex = (_currentIndex + 1) % math.min(widget.books.length, 5);
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _extractColor(Book book, int index) async {
    if (_colorCache.containsKey(index)) {
      if (mounted) setState(() => _currentDominantColor = _colorCache[index]!);
      return;
    }
    
    String finalUrl = '';
    if (book.imageUrl != null && book.imageUrl!.isNotEmpty) {
      finalUrl = book.imageUrl!;
    } else if (book.isbn.isNotEmpty) {
      finalUrl = 'https://covers.openlibrary.org/b/isbn/${book.isbn}-L.jpg';
    }

    if (finalUrl.isNotEmpty) {
      try {
        final paletteGenerator = await PaletteGenerator.fromImageProvider(
          NetworkImage(finalUrl),
        );
        // Ưu tiên màu sáng nhẹ (lightMuted) hoặc màu chủ đạo (dominantColor)
        final color = paletteGenerator.lightMutedColor?.color 
            ?? paletteGenerator.dominantColor?.color 
            ?? const Color(0xFFF0F4F8);
            
        if (mounted) {
          setState(() {
            _colorCache[index] = color;
            _currentDominantColor = color;
          });
        }
      } catch (e) {
        // Fallback color if error
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Widget _buildSparkleText(Widget child, Color baseColor) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, childWidget) {
        // Cho dải sáng quét từ -0.5 tới 1.5 để biến mất hoàn toàn khỏi chữ
        final glowPos = -0.5 + (_sparkleController.value * 2.0);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                baseColor, 
                Colors.white, // Lấp lánh màu sáng
                baseColor
              ],
              stops: [
                glowPos - 0.2,
                glowPos,
                glowPos + 0.2,
              ],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: childWidget,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Center(child: Text("Hiện tại không có dữ liệu", style: TextStyle(color: Colors.grey))),
      );
    }

    final topBooks = widget.books.take(5).toList();
    final currentBook = topBooks[_currentIndex];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          height: 230, // Thu nhỏ tổng thể lại
          margin: const EdgeInsets.only(top: 15), // Chừa chỗ cho Badge đè lên
          width: double.infinity,
          decoration: BoxDecoration(
            color: _currentDominantColor.withOpacity(0.35), // Đậm hơn 1 xíu theo ý người dùng
            borderRadius: BorderRadius.zero, // Khung tổng thành góc vuông
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45), // Bóng đậm hơn
                blurRadius: 15, // Bóng ít lại (gọn hơn)
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _currentDominantColor.withOpacity(0.5), // Bóng màu cũng đậm hơn
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ]
          ),
          child: Stack(
            children: [
              // Ảnh nền làm mờ kéo sát xuống mép dưới và cách đều 2 bên
              if (currentBook.imageUrl != null && currentBook.imageUrl!.isNotEmpty)
                Positioned(
                  left: 35, 
                  right: 35,
                  bottom: 0,
                  top: 70, 
                  child: Opacity(
                    opacity: 0.35, // Đậm hơn xíu xiu nữa
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        // Làm nhạt (mờ) viền xung quanh của ảnh nền
                        return const RadialGradient(
                          center: Alignment.center,
                          radius: 0.7,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.5, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(currentBook.imageUrl!),
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.6), 
                            colorFilter: ColorFilter.mode(_currentDominantColor.withOpacity(0.5), BlendMode.srcOver),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Nội dung chính
              Padding(
                padding: const EdgeInsets.only(top: 25, left: 15, right: 15, bottom: 15),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bên trái: Ảnh sách (Lật trang 3D)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Expanded(
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: topBooks.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index;
                                });
                                _extractColor(topBooks[index], index);
                                _sparkleController.forward(from: 0.0);
                                _startTimer(); // Reset timer khi tự lật
                              },
                          itemBuilder: (context, index) {
                            final book = topBooks[index];
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double page = index.toDouble();
                                if (_pageController.position.haveDimensions) {
                                  page = _pageController.page ?? index.toDouble();
                                }
                                double value = (page - index);
                                
                                // Hiệu ứng lật trang giống sách thật (xoay từ lề trái)
                                double angle = 0.0;
                                Alignment alignment = Alignment.center;
                                
                                if (value > 0) {
                                  // Trang đang lật sang trái
                                  angle = value * (math.pi / -2);
                                  alignment = Alignment.centerLeft; // Bản lề sách bên trái
                                } else {
                                  // Trang đang chờ được lật tới
                                  angle = value * (math.pi / 2);
                                  alignment = Alignment.centerRight; 
                                }

                                return Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.002) // Phối cảnh sâu hơn
                                    ..rotateY(angle),
                                  alignment: alignment,
                                  child: Opacity(
                                    opacity: (1.0 - value.abs() * 0.5).clamp(0.0, 1.0),
                                    child: child,
                                  ),
                                );
                              },
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4), // Giảm bóng để sát vô cuốn sách
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                        offset: const Offset(4, 4), // Thu ngắn khoảng cách
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 1,
                                        spreadRadius: -1,
                                        offset: const Offset(-1, -1), // Viền sáng nhẹ
                                      )
                                    ]
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(5), // Bo cực nhẹ ở góc ngoài mô phỏng góc sách
                                      bottomRight: Radius.circular(5),
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 2/3,
                                      child: (book.imageUrl != null && book.imageUrl!.isNotEmpty) 
                                        ? Image.network(
                                            book.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, e, s) => Container(
                                              color: Colors.grey[200], 
                                              child: const Icon(Icons.book, size: 40, color: Colors.grey)
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[200], 
                                            child: const Icon(Icons.book, size: 40, color: Colors.grey)
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 5 dấu chấm trắng (Indicator)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(topBooks.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 22 : 10,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 25),

              // Bên phải: Tên sách nổi bật hơn
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tên sách: Dùng font chữ sang trọng (Playfair Display)
                    _buildSparkleText(
                      Text(
                        currentBook.title, 
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22, 
                          fontWeight: FontWeight.w900, // Đậm nét hơn
                          color: Colors.black, // Đổi sang màu đen tuyền để chữ nổi bật hẳn
                          height: 1.2,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.3),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            )
                          ],
                        ), 
                        maxLines: 3, 
                        overflow: TextOverflow.ellipsis
                      ),
                      Colors.black,
                    ),
                    const SizedBox(height: 6),
                    // Tác giả: Bỏ chữ "Tác giả:" và để nghiêng nghệ thuật
                    _buildSparkleText(
                      Text(
                        currentBook.author,
                        style: GoogleFonts.lato(
                          fontSize: 14, 
                          color: Colors.black87, 
                          fontWeight: FontWeight.w800, // Tăng độ đậm
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Colors.black87,
                    ),
                    const SizedBox(height: 12),
                    // Mô tả (2 dòng)
                    _buildSparkleText(
                      Text(
                        currentBook.description.isNotEmpty ? currentBook.description : "Chưa có mô tả cho cuốn sách này.",
                        style: const TextStyle(fontSize: 13, color: Color(0xFF2D3142), height: 1.5, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Color(0xFF2D3142),
                    ),
                    const SizedBox(height: 12),
                    // Số trang và thể loại
                    _buildSparkleText(
                      Text(
                        "Số trang: ${currentBook.pages > 0 ? currentBook.pages : 'N/A'} • Thể loại: ${currentBook.categoryName}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E2130), fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Color(0xFF1E2130),
                    ),
                    const SizedBox(height: 3), // Thêm khoảng trống ở dưới để đẩy chữ lên trên
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
  
  // Badge: HOT TUẦN NÀY nổi nửa bên ngoài ở góc trái
        Positioned(
          top: 0,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrangeAccent]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))
              ]
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text("HOT TUẦN NÀY", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
