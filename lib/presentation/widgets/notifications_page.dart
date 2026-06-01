import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const NotificationsPage({super.key, this.userData});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final rawId = widget.userData?['user_id'] ?? widget.userData?['id'];
      if (rawId == null) {
        setState(() {
          _error = "Không xác định được mã người dùng.";
          _isLoading = false;
        });
        return;
      }
      final int userId = rawId is int ? rawId : int.parse(rawId.toString());
      final data = await _apiService.fetchUserNotifications(userId);
      
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
          _error = null;
        });
        _fadeController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Lỗi khi kết nối đến máy chủ: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int index) async {
    final notif = _notifications[index];
    if (notif['is_read'] == true) return;

    final success = await _apiService.markNotificationAsRead(notif['notification_id']);
    if (success && mounted) {
      setState(() {
        _notifications[index]['is_read'] = true;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final rawId = widget.userData?['user_id'] ?? widget.userData?['id'];
    if (rawId == null || _notifications.isEmpty) return;
    
    final int userId = rawId is int ? rawId : int.parse(rawId.toString());
    
    setState(() {
      _isLoading = true;
    });

    final success = await _apiService.markAllNotificationsAsRead(userId);
    if (success) {
      await _loadNotifications();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi khi cập nhật trạng thái thông báo")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD), // Cream premium background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header với nút Đánh dấu đọc tất cả
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "THÔNG BÁO",
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3E2723), // Dark brown
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (_notifications.any((n) => n['is_read'] == false))
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF80A1BA)),
                      label: Text(
                        "Đọc tất cả",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF80A1BA), // Slate blue
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: const Color(0xFF80A1BA).withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Nội dung hiển thị chính
              Expanded(
                child: _buildBodyContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF91C4C3)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF80A1BA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Tải lại", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 80,
                  color: Color(0xFFE2B4B4), // Soft pink-grey
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Hộp thư của bạn đang trống",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Các thông báo mượn trả, nhắc nhở hạn sách\nvà ưu đãi sẽ xuất hiện tại đây.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF91C4C3),
      onRefresh: _loadNotifications,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final item = _notifications[index];
            return _buildNotificationCard(item, index);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index) {
    final String type = item['type'] ?? 'welcome';
    final bool isRead = item['is_read'] ?? false;
    
    // Phân tích styling theo loại thông báo
    IconData iconData = Icons.notifications_active_rounded;
    Color iconBgColor = const Color(0xFFE5F6FF);
    Color iconColor = const Color(0xFF0091FF);

    if (type == 'welcome') {
      iconData = Icons.celebration_rounded;
      iconBgColor = const Color(0xFFE8E5FF);
      iconColor = const Color(0xFF6B4EFF);
    } else if (type == 'like') {
      iconData = Icons.favorite_rounded;
      iconBgColor = const Color(0xFFFFECEF);
      iconColor = const Color(0xFFFF4E64);
    } else if (type == 'borrow_success') {
      iconData = Icons.library_books_rounded;
      iconBgColor = const Color(0xFFE5F6FF);
      iconColor = const Color(0xFF0091FF);
    } else if (type == 'return_success') {
      iconData = Icons.assignment_turned_in_rounded;
      iconBgColor = const Color(0xFFE6FFED);
      iconColor = const Color(0xFF00B050);
    } else if (type == 'due_countdown_3d') {
      iconData = Icons.timer_rounded;
      iconBgColor = const Color(0xFFFFF5E6);
      iconColor = const Color(0xFFFF9500);
    } else if (type == 'due_countdown_1d') {
      iconData = Icons.warning_amber_rounded;
      iconBgColor = const Color(0xFFFFEBEB);
      iconColor = const Color(0xFFD0021B);
    }

    // Format ngày tạo
    String formattedTime = '';
    try {
      final DateTime parsed = DateTime.parse(item['created_at']);
      // Chuyển múi giờ local nếu cần
      final DateTime localTime = parsed.toLocal();
      formattedTime = DateFormat('HH:mm - dd/MM/yyyy').format(localTime);
    } catch (_) {
      formattedTime = item['created_at'].toString().split('T')[0];
    }

    return GestureDetector(
      onTap: () => _markAsRead(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.transparent : iconColor.withOpacity(0.3),
            width: isRead ? 0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isRead 
                  ? Colors.black.withOpacity(0.03) 
                  : iconColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon hình tròn Pastel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            
            // Nội dung chữ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? 'Thông báo',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3E2723),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Chấm tròn xanh chỉ trạng thái chưa đọc
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['content'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedTime,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
