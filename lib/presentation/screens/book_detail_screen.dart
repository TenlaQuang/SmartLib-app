import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import '../../data/models/book.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDescriptionExpanded = false;
  Color _dominantColor = const Color(0xFF80A1BA);
  bool _isLoadingPalette = true;
  
  // Animation controller for the complex multi-stage sequence
  late AnimationController _sequenceController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800), // Total sequence duration (tăng lên ~1s)
    );

    _updatePalette();

    // Chờ cho Hero animation bay từ trang ngoài vào xong (khoảng 500ms) rồi mới bắt đầu chuỗi hiệu ứng
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _sequenceController.forward();
    });
  }

  Future<void> _updatePalette() async {
    final book = widget.book;
    final String imageUrl = (book.imageUrl != null && book.imageUrl!.isNotEmpty)
        ? book.imageUrl!
        : (book.isbn.isNotEmpty ? 'https://covers.openlibrary.org/b/isbn/${book.isbn}-L.jpg' : '');

    if (imageUrl.isNotEmpty) {
      try {
        final paletteGenerator = await PaletteGenerator.fromImageProvider(
          NetworkImage(imageUrl),
        );
        if (mounted) {
          setState(() {
            _dominantColor = paletteGenerator.dominantColor?.color ?? const Color(0xFF80A1BA);
          });
        }
      } catch (e) {}
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final String imageUrl = (book.imageUrl != null && book.imageUrl!.isNotEmpty)
        ? book.imageUrl!
        : (book.isbn.isNotEmpty ? 'https://covers.openlibrary.org/b/isbn/${book.isbn}-L.jpg' : '');
    
    // Calculate margins for the expanding white block
    final screenWidth = MediaQuery.of(context).size.width;
    final bookWidth = 170.0;
    final initialMargin = (screenWidth - bookWidth) / 2; // Matches book width exactly

    return Scaffold(
      backgroundColor: _dominantColor,
      body: Stack(
        children: [
          // 1. Blurred Background Image
          Positioned.fill(
            child: Stack(
              children: [
                if (imageUrl.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.7, // Mở rộng ảnh xuống sâu hơn
                    child: Opacity(
                      opacity: 1.0, // Giảm độ trong suốt để ảnh nền mờ ảo hơn
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // Tăng độ mờ để trộn màu mượt hơn
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0], // Tạo điểm dừng để gradient mượt mà
                        colors: [
                          _dominantColor.withOpacity(0.1), // Trong suốt phần trên để thấy ảnh
                          _dominantColor.withOpacity(0.8), // Đậm dần
                          _dominantColor, // Chuyển hoàn toàn sang màu nền ở dưới để xóa đường cắt
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrolling Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Center(
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: const [SizedBox(width: 60)],
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 35),
                    // Stack chứa Sách và Khối trắng để tạo hiệu ứng xếp chồng
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // --- KHỐI TRẮNG (Chạy từ sau ra, mở rộng ngang, xổ xuống) ---
                        Padding(
                          padding: const EdgeInsets.only(top: 160), // Đưa xuống thêm 30 (từ 100 lên 130)
                          child: AnimatedBuilder(
                            animation: _sequenceController,
                            builder: (context, child) {
                              // Giai đoạn 2: Mở rộng ngang (0.2 -> 0.4)
                              double currentMargin = Tween<double>(begin: initialMargin, end: 12.0).evaluate(
                                CurvedAnimation(parent: _sequenceController, curve: const Interval(0.2, 0.4, curve: Curves.easeOutCubic))
                              );

                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: currentMargin),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7DD),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(40),
                                    topRight: Radius.circular(40),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15 * _sequenceController.value),
                                      blurRadius: 15,
                                      offset: const Offset(0, -5),
                                    )
                                  ]
                                ),
                                child: Column(
                                  children: [
                                    // Giảm độ cao phần đệm để vẫn núp được sau sách (130 + 80 = 210, vẫn nhỏ hơn đáy sách ở 220)
                                    const SizedBox(height: 60), 
                                    // Giai đoạn 3: Xổ xuống (0.4 -> 0.7)
                                    SizeTransition(
                                      sizeFactor: CurvedAnimation(parent: _sequenceController, curve: const Interval(0.4, 0.7, curve: Curves.easeOutQuart)),
                                      axisAlignment: -1.0, // Xổ từ trên xuống
                                      // Giai đoạn 4: Hiển thị nội dung (0.6 -> 1.0)
                                      child: FadeTransition(
                                        opacity: CurvedAnimation(parent: _sequenceController, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
                                        child: child,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: _buildWhiteBoxContent(book), // Chứa toàn bộ nội dung text
                          ),
                        ),

                        // --- ẢNH SÁCH HERO (Nhích lên) ---
                        AnimatedBuilder(
                          animation: _sequenceController,
                          builder: (context, child) {
                            // Giai đoạn 1: Sách nhích lên một chút (0.0 -> 0.25)
                            double nudge = Tween<double>(begin: 0, end: -35).evaluate(
                              CurvedAnimation(parent: _sequenceController, curve: const Interval(0.0, 0.25, curve: Curves.easeOutQuart))
                            );
                            return Transform.translate(
                              offset: Offset(0, nudge),
                              child: child,
                            );
                          },
                          child: Hero(
                            tag: 'book_cover_${book.id}',
                            child: Container(
                              width: 170,
                              height: 255,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6), // Bo góc nhẹ 1 tý ty
                                boxShadow: [
                                  const BoxShadow(
                                    color: Colors.black87, // Viền đen giả lập bằng shadow để bo góc mượt
                                    offset: Offset(0, 2),
                                    blurRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6), // Đảm bảo ảnh cũng bị bo góc
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.book, size: 80, color: Colors.grey),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Bookmark Icon
          Positioned(
            top: 0,
            right: 25,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
                CurvedAnimation(parent: _sequenceController, curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack))
              ),
              child: Icon(
                Icons.bookmark_rounded,
                color: Colors.white,
                size: 55,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tách riêng phần nội dung để code sạch hơn
  Widget _buildWhiteBoxContent(Book book) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            book.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.philosopher(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          book.author,
          style: GoogleFonts.dancingScript(
            fontSize: 22,
            color: const Color(0xFF4A4E69),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20), // Thêm khoảng cách ở đây
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoCard(Icons.menu_book_rounded, "${book.pages > 0 ? book.pages : 'N/A'} Trang"),
          ],
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildTag(book.categoryName, const Color(0xFF5D3A1A)), // Nâu đậm cố định chuyên nghiệp
              if (book.locationZone.isNotEmpty) 
                _buildTag(book.locationZone, const Color(0xFF8BBF88)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 4.5, 
              color: Color.alphaBlend(Colors.black.withOpacity(0.2), _dominantColor), // Làm đậm màu chủ đạo lên một chút
            ),
            insets: const EdgeInsets.symmetric(horizontal: -10.0),
          ),
          labelColor: const Color(0xFF2D3142), // Chữ quay lại màu đen đậm
          unselectedLabelColor: Colors.grey[500],
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16),
          tabs: const [
            Tab(text: "Tổng quan"),
            Tab(text: "Đánh giá"),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: IndexedStack(
            index: _tabController.index,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      book.description.isNotEmpty ? book.description : "Chưa có mô tả cho cuốn sách này.",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF333333),
                        fontSize: 16,
                        height: 1.8,
                      ),
                      maxLines: _isDescriptionExpanded ? null : 5,
                      overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  if (book.description.length > 150)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextButton(
                          onPressed: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                          child: Text(
                            _isDescriptionExpanded ? "Thu gọn" : "Xem thêm",
                            style: const TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("Chưa có đánh giá nào.", style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.grey[600], size: 18),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}
