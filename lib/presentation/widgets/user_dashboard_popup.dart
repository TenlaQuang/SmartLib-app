import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class UserDashboardPopup extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const UserDashboardPopup({
    super.key,
    required this.userData,
    required this.onLogout,
  });

  @override
  State<UserDashboardPopup> createState() => _UserDashboardPopupState();
}

class _UserDashboardPopupState extends State<UserDashboardPopup> {
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
      final data = await _apiService.fetchUserActivity(widget.userData['user_id']);
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

  @override
  Widget build(BuildContext context) {
    final String fullName = widget.userData['full_name'] ?? 'Sinh viên SmartLib';
    final String userCode = widget.userData['user_code'] ?? 'N/A';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Profile
            Row(
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
            const SizedBox(height: 32),
            
            // Activity Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Hoạt động mượn trả",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF80A1BA),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Color(0xFF91C4C3)),
              )
            else if (_error != null)
              Text("Lỗi: $_error", style: const TextStyle(color: Colors.redAccent))
            else ...[
              // Ongoing Books
              _buildSectionTitle("Sách đang mượn (${_activity?['ongoing_count'] ?? 0})"),
              if ((_activity?['ongoing_books'] as List).isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("Bạn đang không mượn cuốn sách nào.", style: TextStyle(color: Colors.grey)),
                )
              else
                ...( _activity?['ongoing_books'] as List).map((item) => _buildTransactionItem(item, isOngoing: true)),

              const SizedBox(height: 24),
              
              // History
              _buildSectionTitle("Lịch sử trả sách (${_activity?['completed_count'] ?? 0})"),
              if ((_activity?['history'] as List).isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("Chưa có lịch sử giao dịch.", style: TextStyle(color: Colors.grey)),
                )
              else
                ...( _activity?['history'] as List).map((item) => _buildTransactionItem(item, isOngoing: false)),
            ],
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7D7D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "ĐĂNG XUẤT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> item, {required bool isOngoing}) {
    final borrowDate = DateTime.parse(item['borrow_date']);
    final dueDate = DateTime.parse(item['due_date']);
    final dateStr = DateFormat('dd/MM/yyyy').format(borrowDate);
    final dueStr = DateFormat('dd/MM/yyyy').format(dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(15),
        border: isOngoing && DateTime.now().isAfter(dueDate) 
            ? Border.all(color: Colors.redAccent.withOpacity(0.5)) 
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isOngoing ? Icons.book_rounded : Icons.check_circle_rounded,
            color: isOngoing 
                ? (DateTime.now().isAfter(dueDate) ? Colors.redAccent : const Color(0xFF91C4C3)) 
                : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['book_title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOngoing ? "Hạn trả: $dueStr" : "Đã trả: $dateStr",
                  style: TextStyle(
                    fontSize: 12, 
                    color: isOngoing && DateTime.now().isAfter(dueDate) ? Colors.redAccent : Colors.grey
                  ),
                ),
              ],
            ),
          ),
          if (isOngoing)
            const Text("Đang mượn", style: TextStyle(fontSize: 10, color: Color(0xFF80A1BA), fontWeight: FontWeight.bold))
          else
            const Text("Hoàn tất", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
