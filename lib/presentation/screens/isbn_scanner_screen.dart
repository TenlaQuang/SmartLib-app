import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../data/models/book.dart';

class IsbnScannerScreen extends StatefulWidget {
  const IsbnScannerScreen({super.key});

  @override
  State<IsbnScannerScreen> createState() => _IsbnScannerScreenState();
}

class _IsbnScannerScreenState extends State<IsbnScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.ean13], // ISBN usually maps to EAN-13
    returnImage: false,
    detectionSpeed: DetectionSpeed.normal,
  );
  
  final ApiService _apiService = ApiService();
  
  // Set lưu các mã ISBN đã quét thành công (chống trùng lặp)
  final Set<String> _scannedIsbns = {};
  
  // Lưu vị trí barcode để vẽ Bounding Box
  List<Barcode> _barcodes = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    bool foundNew = false;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final isbn = barcode.rawValue!;
        // Chỉ thêm nếu là mã mới
        if (!_scannedIsbns.contains(isbn)) {
          _scannedIsbns.add(isbn);
          foundNew = true;
        }
      }
    }

    if (foundNew) {
      // Báo hiệu âm thanh tít và rung
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.vibrate();
    }

    setState(() {
      _barcodes = barcodes;
    });
  }

  void _showConfirmationDialog() async {
    if (_scannedIsbns.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Tạm dừng scanner
    _scannerController.stop();

    // Hiện loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    List<Book> foundBooks = [];
    
    // Tìm từng sách theo ISBN
    for (String isbn in _scannedIsbns) {
      try {
        // Ta sẽ dùng hàm fetchBooks có truyền query param search
        final books = await _apiService.fetchBooks(search: isbn);
        if (books.isNotEmpty) {
          foundBooks.add(books.first);
        }
      } catch (e) {
        debugPrint("Error fetching book for ISBN $isbn: $e");
      }
    }

    // Đóng loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (!mounted) return;

    // Hiện dialog xác nhận
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Đã nhận diện được ${foundBooks.length} cuốn sách",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF80A1BA)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: foundBooks.length,
            itemBuilder: (context, index) {
              final book = foundBooks[index];
              return ListTile(
                leading: const Icon(Icons.book, color: Color(0xFF91C4C3)),
                title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text("ISBN: ${book.isbn}"),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng Dialog
              _scannedIsbns.clear();
              _barcodes.clear();
              setState(() {
                _isProcessing = false;
              });
              _scannerController.start(); // Quét lại
            },
            child: const Text("Quét lại", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF80A1BA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Gửi yêu cầu mượn sách thực tế lên Server
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Yêu cầu mượn sách đã được ghi nhận!")),
              );
              Navigator.pop(context); // Quay về màn trước
            },
            child: const Text("Đồng ý mượn"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Quét ISBN Mượn Sách", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // Lớp vẽ Bounding Box
          CustomPaint(
            painter: BarcodeOverlayPainter(barcodes: _barcodes),
            child: Container(),
          ),

          // Lớp UI che mờ viền
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
            ),
            child: const Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(BorderSide(color: Color(0xFF91C4C3), width: 3)),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
              ),
            ),
          ),
          
          // Hướng dẫn
          const Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Text(
              "Đưa mã vạch sách vào khung hình",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Số lượng sách & Nút xác nhận
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (_scannedIsbns.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Đã bắt được: ${_scannedIsbns.length} mã ISBN",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF80A1BA)),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scannedIsbns.isNotEmpty ? const Color(0xFF80A1BA) : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _scannedIsbns.isNotEmpty ? _showConfirmationDialog : null,
                    child: Text(
                      _scannedIsbns.isNotEmpty ? "Xác nhận mượn (${_scannedIsbns.length} cuốn)" : "Đang chờ quét...",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BarcodeOverlayPainter extends CustomPainter {
  final List<Barcode> barcodes;
  
  BarcodeOverlayPainter({required this.barcodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF91C4C3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (final barcode in barcodes) {
      if (barcode.corners != null) {
        final Path path = Path();
        if (barcode.corners!.isNotEmpty) {
          path.moveTo(barcode.corners![0].dx, barcode.corners![0].dy);
          for (int i = 1; i < barcode.corners!.length; i++) {
            path.lineTo(barcode.corners![i].dx, barcode.corners![i].dy);
          }
          path.close();
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Để đơn giản, luôn vẽ lại khi có tọa độ mới
  }
}
