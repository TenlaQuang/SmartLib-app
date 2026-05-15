import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.userData,
    required this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _activity;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideUpAnimation;
  late Animation<Offset> _slideDownAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _bookSlideUpAnimation;
  late Animation<double> _bookFadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadActivity();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _slideUpAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)),
    );

    _slideDownAnimation = Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.3, 0.6, curve: Curves.elasticOut)),
    );

    _bookSlideUpAnimation = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );

    _bookFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.59, 0.60, curve: Curves.linear)),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadActivity() async {
    try {
      final rawId = widget.userData['user_id'] ?? widget.userData['id'];
      if (rawId == null) throw Exception("Không tìm thấy ID người dùng");
      
      final int userId = rawId is int ? rawId : int.parse(rawId.toString());
      
      final data = await _apiService.fetchUserActivity(userId);
      if (mounted) {
        setState(() {
          _activity = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showBottomSheet(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF80A1BA)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFF91C4C3),
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 20),
        _buildInfoRow("Họ và Tên", widget.userData['full_name'] ?? 'N/A'),
        _buildInfoRow("Mã Sinh Viên", widget.userData['user_code'] ?? 'N/A'),
        _buildInfoRow("Email", widget.userData['email'] ?? 'Chưa cập nhật'),
        _buildInfoRow("Số điện thoại", widget.userData['phone'] ?? 'Chưa cập nhật'),
        _buildInfoRow("User ID", (widget.userData['user_id'] ?? widget.userData['id'] ?? 'N/A').toString()),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActivityList(bool isOngoing) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Text("Lỗi: $_error", style: const TextStyle(color: Colors.redAccent));
    
    final listKey = isOngoing ? 'ongoing_books' : 'history';
    final list = _activity?[listKey] as List?;
    
    if (list == null || list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("Không có dữ liệu.", style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    
    return Column(
      children: list.map((item) => _buildTransactionItem(item, isOngoing: isOngoing)).toList(),
    );
  }

  String _getAvatarLetter(String fullName) {
    if (fullName.isEmpty) return 'U';
    final parts = fullName.trim().split(' ');
    return parts.last[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = widget.userData['full_name'] ?? 'Sinh viên SmartLib';
    final String userCode = widget.userData['user_code'] ?? 'N/A';
    final String avatarLetter = _getAvatarLetter(fullName);
    
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723), // Dark brown background
      body: Stack(
        children: [
          // 1. Background Layer (Dark top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideDownAnimation,
                child: Container(
                  color: const Color(0xFF3E2723),
                ),
              ),
            ),
          ),
          
          // 1.5. Book Stacks Layer (Animated last, from bottom)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                // Left Book Stack
                Positioned(
                  left: -60,
                  top: 12,
                  width: 350,
                  height: 300,
                  child: FadeTransition(
                    opacity: _bookFadeAnimation,
                    child: SlideTransition(
                      position: _bookSlideUpAnimation,
                      child: Image.asset(
                        'assets/images/book_stack_left.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Right Book Stack
                Positioned(
                  right: 10,
                  top: 36,
                  width: 230,
                  height: 230,
                  child: FadeTransition(
                    opacity: _bookFadeAnimation,
                    child: SlideTransition(
                      position: _bookSlideUpAnimation,
                      child: Image.asset(
                        'assets/images/book_stack_right.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Content Layer (Scrollable)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideUpAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                // Transparent space for the top header area
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                ),
                
                // Main Content Container
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7DD),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(95)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
                    child: Column(
                      children: [
                        // Name and ID
                        Text(
                          fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "@$userCode",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 10),

                        // Bookshelves Section
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Tủ sách của bạn",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildShelfCard(
                                title: "Đã đọc",
                                count: _activity?['completed_count'] ?? 0,
                                color: const Color(0xFFE5B97B),
                                onTap: () => _showBottomSheet("Lịch sử mượn trả", _buildActivityList(false)),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildShelfCard(
                                title: "Đang mượn",
                                count: _activity?['ongoing_count'] ?? 0,
                                color: const Color(0xFF91C4C3),
                                onTap: () => _showBottomSheet("Sách đang mượn", _buildActivityList(true)),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildShelfCard(
                                title: "Yêu thích",
                                count: 0,
                                color: const Color(0xFFE2B4B4),
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Personal Info Action
                        _buildActionRow(
                          icon: Icons.badge_rounded,
                          title: "Thông tin chi tiết",
                          onTap: () => _showBottomSheet("Thông tin cá nhân", _buildPersonalInfo()),
                        ),
                        const Divider(),
                        _buildActionRow(
                          icon: Icons.settings_rounded,
                          title: "Cài đặt tài khoản",
                          onTap: () {},
                        ),

                        const Spacer(),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: widget.onLogout,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "Đăng xuất",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
            ),
          ),

          // 3. Avatar Layer (Floating)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18 - 50,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFF7DD), width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
                color: const Color(0xFF91C4C3),
              ),
              child: Center(
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildShelfCard({
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(2, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            // Spine shading (Left)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 15,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Spine line
            Positioned(
              left: 15,
              top: 0,
              bottom: 0,
              width: 1,
              child: Container(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            // Pages at the bottom
            Positioned(
              left: 10,
              right: 2,
              bottom: 0,
              height: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: color.withOpacity(0.5), width: 1),
                ),
              ),
            ),
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, bottom: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF3E2723),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "($count)",
                      style: const TextStyle(
                        color: Color(0xFF3E2723),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3E2723), size: 24),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3142),
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> item, {required bool isOngoing}) {
    final DateTime? borrowDate = item['borrow_date'] != null ? DateTime.parse(item['borrow_date']) : null;
    final DateTime? dueDate = item['due_date'] != null ? DateTime.parse(item['due_date']) : null;
    final DateTime? returnDate = item['return_date'] != null ? DateTime.parse(item['return_date']) : null;
    
    final dateStr = borrowDate != null ? DateFormat('dd/MM/yyyy').format(borrowDate) : 'N/A';
    final dueStr = dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate) : 'N/A';
    final returnStr = returnDate != null ? DateFormat('dd/MM/yyyy').format(returnDate) : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isOngoing && dueDate != null && DateTime.now().isAfter(dueDate) 
            ? Border.all(color: Colors.redAccent.withOpacity(0.5)) 
            : Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isOngoing ? Icons.book_rounded : Icons.check_circle_rounded,
            color: isOngoing 
                ? (dueDate != null && DateTime.now().isAfter(dueDate) ? Colors.redAccent : const Color(0xFF91C4C3)) 
                : Colors.grey,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['book_title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isOngoing ? "Hạn trả: $dueStr" : "Đã trả: $returnStr",
                  style: TextStyle(
                    fontSize: 14, 
                    color: isOngoing && dueDate != null && DateTime.now().isAfter(dueDate) ? Colors.redAccent : Colors.grey
                  ),
                ),
              ],
            ),
          ),
          if (isOngoing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF80A1BA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Đang mượn", style: TextStyle(fontSize: 12, color: Color(0xFF80A1BA), fontWeight: FontWeight.bold)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Hoàn tất", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
