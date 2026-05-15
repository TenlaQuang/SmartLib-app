class Book {
  final int id;
  final String title;
  final String author;
  final String status;
  final String isbn;
  final String categoryName;
  final String locationZone;
  final double marketPrice;
  final String? imageUrl;
  final String description;
  final int pages;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.isbn,
    required this.categoryName,
    required this.locationZone,
    required this.marketPrice,
    this.imageUrl,
    this.description = '',
    this.pages = 0,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['book_id'] ?? 0,
      title: json['title']?.toString() ?? 'Không có tiêu đề',
      author: json['author']?.toString() ?? 'Không rõ tác giả',
      status: json['status']?.toString() ?? 'N/A',
      isbn: json['isbn']?.toString() ?? '',
      categoryName: json['category'] is String 
          ? json['category'].toString() 
          : (json['category'] is Map && json['category']['name'] != null) 
              ? json['category']['name'].toString() 
              : 'Thể loại khác',
      locationZone: (json['location'] != null)
          ? "${json['location']['zone_name'] ?? ''} - ${json['location']['shelf_id'] ?? ''} - Tầng ${json['location']['level_number'] ?? ''}"
          : '',
      marketPrice: json['market_price'] != null 
          ? double.tryParse(json['market_price'].toString()) ?? 0.0 
          : 0.0,
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString() ?? 'Chưa có mô tả cho cuốn sách này.',
      pages: json['pages'] != null ? int.tryParse(json['pages'].toString()) ?? 0 : 0,
    );
  }
}
