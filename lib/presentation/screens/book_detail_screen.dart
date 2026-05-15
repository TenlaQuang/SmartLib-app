import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import '../../data/models/book.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

String optimizeCloudinaryUrl(String url, {int width = 400}) {
  if (url.isEmpty) return url;
  if (url.contains('res.cloudinary.com') && url.contains('/upload/')) {
    if (!url.contains('/upload/q_auto')) {
      return url.replaceFirst('/upload/', '/upload/q_auto,f_auto,w_$width/');
    }
  }
  return url;
}

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final Map<String, dynamic>? userData;
  const BookDetailScreen({super.key, required this.book, this.userData});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDescriptionExpanded = false;
  Color _dominantColor = const Color(0xFF80A1BA);
  bool _isLoadingPalette = true;
  
  List<Book> _relatedBooks = [];
  bool _isLoadingRelated = true;
  
  // Animation controller for the complex multi-stage sequence
  late AnimationController _sequenceController;

  bool _isFavorite = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  final TextEditingController _commentController = TextEditingController();
  int _userRating = 5;

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
    _fetchRelatedBooks();
    _checkFavoriteStatus();
    _fetchComments();

    // Chờ cho Hero animation bay từ trang ngoài vào xong (khoảng 500ms) rồi mới bắt đầu chuỗi hiệu ứng
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _sequenceController.forward();
    });
  }

  Future<void> _updatePalette() async {
    final book = widget.book;
    final String rawImageUrl = (book.imageUrl != null && book.imageUrl!.isNotEmpty)
        ? book.imageUrl!
        : (book.isbn.isNotEmpty ? 'https://covers.openlibrary.org/b/isbn/${book.isbn}-L.jpg' : '');
    final String imageUrl = optimizeCloudinaryUrl(rawImageUrl, width: 200); // Rất nhỏ để trích xuất màu nhanh

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

  Future<void> _fetchRelatedBooks() async {
    try {
      final ApiService apiService = ApiService();
      final books = await apiService.getRelatedBooks(widget.book.id);
      if (mounted) {
        setState(() {
          _relatedBooks = books;
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.userData == null) return;
    final int userId = widget.userData!['user_id'] ?? widget.userData!['id'];
    final isFav = await ApiService().checkIsFavorite(userId, widget.book.id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _fetchComments() async {
    final comments = await ApiService().fetchBookComments(widget.book.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập để sử dụng tính năng này")));
      return;
    }
    final int userId = widget.userData!['user_id'] ?? widget.userData!['id'];
    final success = await ApiService().toggleFavorite(userId, widget.book.id);
    if (success && mounted) {
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  Future<void> _submitComment() async {
    if (widget.userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập để bình luận")));
      return;
    }
    if (_commentController.text.trim().isEmpty) return;

    final int userId = widget.userData!['user_id'] ?? widget.userData!['id'];
    final success = await ApiService().postComment(
      userId, 
      widget.book.id, 
      _commentController.text.trim(), 
      _userRating
    );

    if (success) {
      _commentController.clear();
      _fetchComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi bình luận!")));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sequenceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final String rawImageUrl = (book.imageUrl != null && book.imageUrl!.isNotEmpty)
        ? book.imageUrl!
        : (book.isbn.isNotEmpty ? 'https://covers.openlibrary.org/b/isbn/${book.isbn}-L.jpg' : '');
    final String bgImageUrl = optimizeCloudinaryUrl(rawImageUrl, width: 600);
    final String coverImageUrl = optimizeCloudinaryUrl(rawImageUrl, width: 400);
    
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
                if (rawImageUrl.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.7, // Mở rộng ảnh xuống sâu hơn
                    child: Opacity(
                      opacity: 1.0, // Giảm độ trong suốt để ảnh nền mờ ảo hơn
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // Tăng độ mờ để trộn màu mượt hơn
                        child: Image.network(bgImageUrl, fit: BoxFit.cover),
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
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
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
                              icon: Icon(
                                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                                color: _isFavorite ? Colors.redAccent : Colors.white, 
                                size: 24
                              ),
                              onPressed: _toggleFavorite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                                child: coverImageUrl.isNotEmpty
                                    ? Image.network(coverImageUrl, fit: BoxFit.cover)
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
              if (book.categoryName.isNotEmpty && book.categoryName != 'Thể loại khác')
                _buildTag(book.categoryName, const Color(0xFF5D3A1A)),
              if (book.locationZone.isNotEmpty && !book.locationZone.contains('null')) 
                _buildTag(book.locationZone, const Color(0xFF8BBF88)),
              if (book.categoryName == 'Thể loại khác' && book.locationZone.isEmpty)
                _buildTag("Đang cập nhật thông tin", Colors.grey[600]!),
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
          padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 30.0, bottom: 10.0),
          child: _tabController.index == 0
            ? Column(
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
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Write Review Card ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          "Đánh giá của bạn",
                          style: GoogleFonts.philosopher(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Star rating - full row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Mức độ yêu thích:",
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                            ),
                            Row(
                              children: List.generate(5, (index) => GestureDetector(
                                onTap: () => setState(() => _userRating = index + 1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(
                                    index < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: index < _userRating ? const Color(0xFFFFC107) : Colors.grey[350],
                                    size: 26,
                                  ),
                                ),
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Text field
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2D3142)),
                          decoration: InputDecoration(
                            hintText: "Chia sẻ cảm nhận của bạn...",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2D3142), width: 1.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitComment,
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: Text("Gửi đánh giá", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D3142),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // ── Reviews list header ──
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3142),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Tất cả đánh giá",
                        style: GoogleFonts.philosopher(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      if (_comments.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3142),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_comments.length}",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingComments)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(color: Color(0xFF2D3142)),
                    ))
                  else if (_comments.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 50, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            "Chưa có đánh giá nào.\nHãy là người đầu tiên!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ))
                  else
                    ..._comments.map((c) {
                      final name = c['user_name'] ?? "Nặc danh";
                      final initial = name.isNotEmpty ? name.trim().split(' ').last[0].toUpperCase() : 'U';
                      final rating = c['rating'] ?? 5;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF91C4C3),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF2D3142)),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: List.generate(5, (index) => Icon(
                                          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: index < rating ? const Color(0xFFFFC107) : Colors.grey[300],
                                          size: 14,
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  c['created_at'] != null
                                      ? DateFormat('dd/MM/yy').format(DateTime.parse(c['created_at']))
                                      : "",
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                            if ((c['content'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 3,
                                    height: 50,
                                    margin: const EdgeInsets.only(right: 10, top: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF91C4C3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      c['content'] ?? "",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF555555),
                                        fontSize: 14,
                                        height: 1.6,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
        ),
        _buildRelatedBooks(),
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

  Widget _buildRelatedBooks() {
    if (_isLoadingRelated) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF2D3142))),
      );
    }
    
    if (_relatedBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DD).withOpacity(0.5), // Tiệp màu với khối trắng nhưng mờ hơn
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 50, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Sách liên quan",
                  style: GoogleFonts.philosopher(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 230,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _relatedBooks.length,
              itemBuilder: (context, index) {
                final relatedBook = _relatedBooks[index];
                final String rawImageUrl = (relatedBook.imageUrl != null && relatedBook.imageUrl!.isNotEmpty)
                    ? relatedBook.imageUrl!
                    : (relatedBook.isbn.isNotEmpty ? 'https://covers.openlibrary.org/b/isbn/${relatedBook.isbn}-L.jpg' : '');
                final String coverImageUrl = optimizeCloudinaryUrl(rawImageUrl, width: 200);
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: relatedBook, userData: widget.userData),
                      ),
                    );
                  },
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book Cover with premium shadow
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.book_rounded, color: Colors.grey, size: 40),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            relatedBook.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3142),
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
