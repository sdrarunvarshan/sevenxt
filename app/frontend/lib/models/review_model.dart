class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String productId;
  final double rating;
  final String comment;
  final DateTime date;
  final List<String>? images;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.date,
    this.images,
  });
  bool isMine(String currentUserId) => userId == currentUserId;

  factory ReviewModel.fromJson(Map<String, dynamic> json, String productId) {
    return ReviewModel(
      id: json['id'],
      userId: json['user_id'] ?? '',
      userName: json['full_name'] ?? json['email'] ?? 'User',
      productId: productId,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] ?? '',
      date: DateTime.parse(json['created_at']),
    );
  }
}
