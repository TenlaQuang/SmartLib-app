class Book {
  final int id;
  final String title;
  final String status;
  final String isbn;
  final String categoryName;
  final String locationZone;
  final double marketPrice;
  final String? imageUrl;

  Book({
    required this.id,
    required this.title,
    required this.status,
    required this.isbn,
    required this.categoryName,
    required this.locationZone,
    required this.marketPrice,
    this.imageUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['book_id'] ?? 0,
      title: json['title'] ?? 'Unknown Book',
      status: json['status'] ?? 'N/A',
      isbn: json['isbn'] ?? '',
      categoryName: json['category'] != null ? json['category']['name'] : 'Thể loại khác',
      locationZone: json['location'] != null ? json['location']['zone_name'] ?? '' : '',
      marketPrice: json['market_price'] != null ? double.tryParse(json['market_price'].toString()) ?? 0.0 : 0.0,
      imageUrl: json['image_url']?.toString(),
    );
  }
}
