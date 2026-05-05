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

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _activity;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    try {
      final userId = widget.userData['user_id'];
      if (userId == null) throw Exception("Không tìm thấy ID người dùng");
      
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
        _buildInfoRow("User ID", widget.userData['user_id']?.toString() ?? 'N/A'),
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

  @override
  Widget build(BuildContext context) {
    final String fullName = widget.userData['full_name'] ?? 'Sinh viên SmartLib';
    final String userCode = widget.userData['user_code'] ?? 'N/A';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7DD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header: Profile
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF91C4C3), Color(0xFF80A1BA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "MSSV: $userCode",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Menu Buttons
              _buildMenuButton(
                icon: Icons.badge_rounded,
                title: "Thông tin cá nhân",
                color: const Color(0xFF80A1BA),
                onTap: () => _showBottomSheet("Thông tin cá nhân", _buildPersonalInfo()),
              ),
              _buildMenuButton(
                icon: Icons.book_rounded,
                title: "Sách đang mượn",
                subtitle: _isLoading ? "Đang tải..." : "${_activity?['ongoing_count'] ?? 0} cuốn",
                color: const Color(0xFF91C4C3),
                onTap: () => _showBottomSheet("Sách đang mượn", _buildActivityList(true)),
              ),
              _buildMenuButton(
                icon: Icons.history_rounded,
                title: "Lịch sử đã mượn",
                subtitle: _isLoading ? "Đang tải..." : "${_activity?['completed_count'] ?? 0} giao dịch",
                color: Colors.orangeAccent,
                onTap: () => _showBottomSheet("Lịch sử mượn trả", _buildActivityList(false)),
              ),
              _buildMenuButton(
                icon: Icons.favorite_rounded,
                title: "Sách yêu thích",
                color: Colors.pinkAccent,
                onTap: () => _showBottomSheet(
                  "Sách yêu thích", 
                  const Center(child: Text("Tính năng đang phát triển", style: TextStyle(color: Colors.grey)))
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: const Text(
                    "ĐĂNG XUẤT",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7D7D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
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
