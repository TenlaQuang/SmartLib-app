import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../data/models/book.dart';
import 'dart:convert';

class ScannerPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isActive;
  final VoidCallback? onTransactionComplete;
  const ScannerPage({
    super.key, 
    this.userData, 
    this.isActive = true,
    this.onTransactionComplete,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.ean13], // ISBN usually maps to EAN-13
    detectionSpeed: DetectionSpeed.normal,
    autoStart: false, // Prevent camera from starting automatically in background
  );
  
  final ApiService _apiService = ApiService();
  
  // Lưu trữ mã ISBN đã quét để chống trùng lặp
  final Set<String> _scannedIsbns = {};
  
  // Lưu trữ chi tiết sách đã quét thành công
  final List<Book> _scannedBooks = [];
  
  // Biến cờ để chống việc xử lý quét liên tục cùng 1 lúc
  bool _isProcessing = false;

  // Chế độ Mượn hoặc Trả sách
  bool _isReturnMode = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void didUpdateWidget(covariant ScannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _scannerController.start();
      } else {
        _scannerController.stop();
      }
    }
  }

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

    // Khởi động camera nếu tab đang active ngay từ đầu
    if (widget.isActive) {
      _scannerController.start();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final rawId = widget.userData?['user_id'] ?? widget.userData?['id'];
    if (rawId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi: Không tìm thấy thông tin đăng nhập!"), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }
    final int userId = rawId is int ? rawId : int.parse(rawId.toString());

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
          if (_isReturnMode) {
            // Chế độ Trả sách: Kiểm tra xem User có đang mượn sách này không
            final bool isBorrowed = await _apiService.checkOngoingBorrow(userId, newIsbn!);
            if (isBorrowed) {
              final book = books.first;
              setState(() {
                _scannedIsbns.add(newIsbn!);
                _scannedBooks.add(book);
              });
              SystemSound.play(SystemSoundType.click);
              HapticFeedback.vibrate();
            } else {
              _scannedIsbns.add(newIsbn!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Bạn không đang mượn cuốn sách '${books.first.title}' này!"),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          } else {
            // Chế độ Mượn sách: Chỉ lấy những cuốn sách đang 'available'
            final availableBooks = books.where((b) => b.status == 'available').toList();

            if (availableBooks.isNotEmpty) {
              final book = availableBooks.first;
              setState(() {
                _scannedIsbns.add(newIsbn!);
                _scannedBooks.add(book);
              });
              SystemSound.play(SystemSoundType.click);
              HapticFeedback.vibrate();
            } else {
              // Sách có trong hệ thống nhưng không còn cuốn nào rảnh
              _scannedIsbns.add(newIsbn!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sách này hiện đã được mượn hết hoặc không có sẵn!"),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
        } else {
          // Nếu không tìm thấy sách, vẫn thêm vào set để không quét lại liên tục
          _scannedIsbns.add(newIsbn!);
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

  void _submitRequest() async {
    if (_scannedBooks.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (widget.userData == null) {
        throw Exception('Vui lòng đăng nhập để thao tác.');
      }
      
      final userId = widget.userData!['user_id'] ?? widget.userData!['id'];
      
      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng.');
      }

      List<String> isbns = _scannedBooks.map((b) => b.isbn).toList();
      
      final requestId = _isReturnMode 
          ? await _apiService.createReturnRequest(userId, isbns)
          : await _apiService.createBorrowRequest(userId, isbns);

      if (requestId != null && mounted) {
        _showWaitingDialog(requestId);
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
    }
  }

  void _showWaitingDialog(int requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: Color(0xFF91C4C3),
                  strokeWidth: 5,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Đang chờ duyệt...",
                style: TextStyle(color: Color(0xFF91C4C3), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Vui lòng gửi sách cho thủ thư và chờ duyệt.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );

    // Bắt đầu vòng lặp kiểm tra trạng thái (polling)
    _startPolling(requestId);
  }

  void _startPolling(int requestId) async {
    bool isApproved = false;
    
    while (!isApproved && mounted) {
      await Future.delayed(const Duration(seconds: 3)); // Kiểm tra mỗi 3 giây
      
      try {
        final status = _isReturnMode 
            ? await _apiService.getReturnRequestStatus(requestId)
            : await _apiService.getBorrowRequestStatus(requestId);
            
        if (status == 'approved') {
          isApproved = true;
        } else if (status == 'rejected') {
          // Nếu bị từ chối, có thể hiện thông báo rồi đóng
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Yêu cầu của bạn đã bị từ chối."), backgroundColor: Colors.orange),
            );
          }
          return;
        }
      } catch (e) {
        // Bỏ qua lỗi kết nối trong lúc polling
      }
    }

    if (isApproved && mounted) {
      Navigator.pop(context); // Đóng Dialog chờ
      
      // Hiện thông báo thành công ngắn gọn
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isReturnMode ? "Yêu cầu trả sách đã được duyệt thành công!" : "Yêu cầu mượn sách đã được duyệt thành công!"),
          backgroundColor: const Color(0xFF91C4C3),
        ),
      );

      setState(() {
        _scannedIsbns.clear();
        _scannedBooks.clear();
      });

      // Kích hoạt callback khi giao dịch thành công
      widget.onTransactionComplete?.call();
    }
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
          
          Positioned(
            top: screenHeight * 0.06,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220, // Kích thước cố định cho hiệu ứng trượt
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Stack(
                  children: [
                    // Khối màu trượt (Chung 1 màu Teal)
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: _isReturnMode ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 110,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF91C4C3),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    // Chữ phía trên
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isReturnMode = false;
                              _scannedIsbns.clear();
                              _scannedBooks.clear();
                            }),
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: Text(
                                "Mượn sách",
                                style: TextStyle(
                                  color: !_isReturnMode ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isReturnMode = true;
                              _scannedIsbns.clear();
                              _scannedBooks.clear();
                            }),
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: Text(
                                "Trả sách",
                                style: TextStyle(
                                  color: _isReturnMode ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
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
            ),
          ),

          // Khung ngắm viền mỏng (Căn xuống một chút để nhường chỗ cho nút gạt)
          Positioned(
            top: screenHeight * 0.15,
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
            top: screenHeight * 0.15 + 170, // Đặt ngay dưới khung ngắm
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
                height: screenHeight * 0.53, // Giảm từ 60% xuống 55% để sít xuống dưới hơn
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
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isReturnMode ? const Color(0xFF3E2723) : const Color(0xFF80A1BA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: _scannedBooks.isNotEmpty ? 5 : 0,
                          ),
                          onPressed: _scannedBooks.isNotEmpty ? _submitRequest : null,
                          child: Opacity(
                            opacity: _scannedBooks.isNotEmpty ? 1.0 : 0.5,
                            child: Text(
                              _isReturnMode ? "GỬI YÊU CẦU TRẢ SÁCH" : "GỬI YÊU CẦU MƯỢN SÁCH",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            ),
                          ),
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
