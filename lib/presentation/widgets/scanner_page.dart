import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../data/models/book.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.ean13], // ISBN usually maps to EAN-13
    detectionSpeed: DetectionSpeed.normal,
  );
  
  final ApiService _apiService = ApiService();
  
  // Lưu trữ mã ISBN đã quét để chống trùng lặp
  final Set<String> _scannedIsbns = {};
  
  // Lưu trữ chi tiết sách đã quét thành công
  final List<Book> _scannedBooks = [];
  
  // Biến cờ để chống việc xử lý quét liên tục cùng 1 lúc
  bool _isProcessing = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0), // Bắt đầu từ dưới đáy màn hình
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Tự động chạy animation khi mở trang
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    String? newIsbn;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final isbn = barcode.rawValue!;
        if (!_scannedIsbns.contains(isbn)) {
          newIsbn = isbn;
          break; // Chỉ xử lý 1 mã mới mỗi lần detect
        }
      }
    }

    if (newIsbn != null) {
      setState(() {
        _isProcessing = true;
      });

      // Tạm dừng scanner trong lúc fetch API
      _scannerController.stop();

      try {
        // Fetch book info from API
        final books = await _apiService.fetchBooks(search: newIsbn);
        if (books.isNotEmpty) {
          final book = books.first;
          setState(() {
            _scannedIsbns.add(newIsbn!);
            _scannedBooks.add(book);
          });
          
          // Phát âm thanh & rung khi quét thành công 1 cuốn mới
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.vibrate();
        } else {
          // Nếu không tìm thấy sách, vẫn thêm vào set để không quét lại liên tục, 
          // nhưng không hiển thị trong list.
          // Hoặc có thể hiện thông báo lỗi.
          _scannedIsbns.add(newIsbn);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Không tìm thấy sách với mã ISBN: $newIsbn"),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        setState(() {
          _isProcessing = false;
        });
        // Tiếp tục quét
        if (mounted) {
          _scannerController.start();
        }
      }
    }
  }

  void _submitBorrowRequest() {
    if (_scannedBooks.isEmpty) return;

    // TODO: Thực tế sẽ gọi API ở đây. Hiện tại chỉ giả lập UI.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Thành công", style: TextStyle(color: Color(0xFF91C4C3))),
        content: Text("Đã gửi yêu cầu mượn ${_scannedBooks.length} cuốn sách lên hệ thống."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng hộp thoại
              setState(() {
                _scannedIsbns.clear();
                _scannedBooks.clear();
              });
            },
            child: const Text("Đóng", style: TextStyle(color: Color(0xFF80A1BA), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black, // Nền đen sau camera
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // CAMERA QUÉT MÃ (Trải dài toàn màn hình)
          // ---------------------------------------------------------
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
          
          // Khung ngắm viền mỏng (Căn lên trên để không bị list che)
          Positioned(
            top: screenHeight * 0.10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF91C4C3), width: 2),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.transparent, // Để camera xuyên thấu
                ),
                child: _isProcessing 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF91C4C3)))
                  : null,
              ),
            ),
          ),
          
          // Dòng chữ hướng dẫn
          Positioned(
            top: screenHeight * 0.10 + 170, // Đặt ngay dưới khung ngắm
            left: 0,
            right: 0,
            child: const Text(
              "Đưa mã vạch (ISBN) vào khung hình",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),

          // ---------------------------------------------------------
          // PHẦN DƯỚI (3/5): DANH SÁCH & NÚT GỬI YÊU CẦU
          // ---------------------------------------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                height: screenHeight * 0.6, // Chiếm 60% màn hình
                width: double.infinity,
                decoration: const BoxDecoration(
                color: Color(0xFFFFF7DD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                children: [
                  // Tiêu đề danh sách
                  Padding(
                    padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sách đã quét",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF91C4C3).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_scannedBooks.length} cuốn",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF91C4C3)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Danh sách sách
                  Expanded(
                    child: _scannedBooks.isEmpty
                        ? const Center(
                            child: Text(
                              "Chưa có cuốn sách nào được quét.",
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _scannedBooks.length,
                            itemBuilder: (context, index) {
                              final book = _scannedBooks[index];
                              return TweenAnimationBuilder<double>(
                                key: ValueKey(book.isbn), // Đảm bảo hiệu ứng diễn ra 1 lần cho 1 cuốn
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(begin: 0, end: 1),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 50 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildScannedBookItem(book, index),
                              );
                            },
                          ),
                  ),

                  // Nút Gửi yêu cầu cố định ở đáy
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _scannedBooks.isNotEmpty ? const Color(0xFF80A1BA) : Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: _scannedBooks.isNotEmpty ? 3 : 0,
                        ),
                        onPressed: _scannedBooks.isNotEmpty ? _submitBorrowRequest : null,
                        child: const Text(
                          "GỬI YÊU CẦU MƯỢN SÁCH",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildScannedBookItem(Book book, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Số thứ tự
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7DD),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5B97B)),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5B97B)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Ảnh sách
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 70,
              child: (book.imageUrl != null && book.imageUrl!.isNotEmpty)
                  ? Image.network(book.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 15),
          // Chi tiết
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Tác giả: ${book.author}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "ISBN: ${book.isbn}",
                  style: const TextStyle(color: Color(0xFF91C4C3), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Nút xóa
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _scannedBooks.removeAt(index);
                // Xóa khỏi set để có thể quét lại nếu muốn
                _scannedIsbns.remove(book.isbn);
              });
            },
          ),
        ],
      ),
    );
  }
}
