import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sevenext/constants.dart';
import 'package:sevenext/models/product_model.dart';
import 'package:sevenext/models/review_model.dart';
import 'package:sevenext/route/api_service.dart';
import 'package:sevenext/screens/reviews/view/components/review_product_card.dart';

class ProductReviewsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductReviewsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  bool _submitting = false;

  List<ReviewModel> _reviews = [];
  ReviewModel? _myReview;

  double _avgRating = 0;
  int _totalReviews = 0;

  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;

  bool _isGuest = true;
  String? _currentUserId;

  final Map<int, int> starCount = {
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0,
  };

  // ========================= INIT =========================
  @override
  void initState() {
    super.initState();
    _loadAuthUser();
    _loadReviews();

  }

  void _loadAuthUser() {
    final authBox = Hive.box('auth');
    _isGuest = authBox.get('is_guest', defaultValue: true);
    _currentUserId = authBox.get('user_id');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ========================= LOAD REVIEWS =========================
  Future<void> _loadReviews() async {
    setState(() => _loading = true);

    try {
      final response = await _api.getProductReviews(
        widget.product.id,
        limit: 50,
      );

      final List list = response['reviews'] ?? [];

      _reviews =
          list.map((e) => ReviewModel.fromJson(e, widget.product.id)).toList();

      _avgRating = (response['average_rating'] ?? 0).toDouble();
      _totalReviews = response['total'] ?? 0;

      starCount.updateAll((key, value) => 0);
      for (final r in _reviews) {
        starCount[r.rating.round()] =
            (starCount[r.rating.round()] ?? 0) + 1;
      }

      // 🔥 FIND CURRENT USER REVIEW (SAFE)
      // 🔥 FIND CURRENT USER REVIEW (SAFE & ROBUST)
      _myReview = null;
      if (!_isGuest && _currentUserId != null) {
        try {
          _myReview = _reviews.firstWhere(
                (r) => r.userId == _currentUserId,
            orElse: () =>  throw Exception(),
          );
        } catch (e) {
          _myReview = null;
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ========================= ADD REVIEW =========================
  Future<void> _submitReview() async {
    if (_rating == 0) return;

    setState(() => _submitting = true);

    try {
      await _api.addReview(
        widget.product.id,
        _rating,
        _commentController.text.trim(),
      );

      // Clear form immediately
      _rating = 0;
      _commentController.clear();

      // Reload reviews and force UI update
      await _loadReviews();

      // Optional: Extra safety - force rebuild
      if (mounted) {
        setState(() {}); // Ensures "Write a Review" disappears immediately
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully")),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit review or review already submitted")),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ========================= EDIT REVIEW =========================
  // In _editReview method - improved
  void _editReview(ReviewModel review) {
    // Use local variables to avoid affecting the main form
    double editRating = review.rating;
    final TextEditingController editController = TextEditingController(text: review.comment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Better keyboard handling
          left: defaultPadding,
          right: defaultPadding,
          top: defaultPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Edit Your Review",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: editRating,
              minRating: 1,
              itemCount: 5,
              itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (v) => editRating = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Share your experience...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (editRating == 0) return;

                      try {
                        await _api.updateReview(
                          review.id,
                          editRating,
                          editController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          await _loadReviews(); // Refresh reviews including _myReview
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Review updated")),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update review")),
                          );
                        }
                      }
                    },
                    child: const Text("Update Review"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    // Cleanup controller when bottom sheet closes
    // (Optional but good practice)
    // Note: We can't easily listen to pop here, but since it's short-lived, it's fine.
  }

  // ========================= DELETE REVIEW =========================
  Future<void> _deleteReview(String reviewId) async {
    await _api.deleteReview(reviewId);
    _loadReviews();
  }

  // ========================= UI =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Reviews")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReviewProductInfoCard(
              image: widget.product.image,
              title: widget.product.title,
              brand: widget.product.brandName,
            ),

            const SizedBox(height: defaultPadding),

            _RatingSummary(
              avgRating: _avgRating,
              totalReviews: _totalReviews,
              starCount: starCount,
            ),

            const SizedBox(height: defaultPadding),

            if (_reviews.isEmpty)
              const Center(child: Text("No reviews yet"))
            else
              ..._reviews.map(
                    (r) => _ReviewTile(
                  review: r,
                  currentUserId: _currentUserId ?? "",
                  onEdit: () => _editReview(r),
                  onDelete: () => _deleteReview(r.id),
                ),
              ),

            const SizedBox(height: defaultPadding),

            // ✅ WRITE REVIEW (ONLY IF NOT REVIEWED)
            if (!_isGuest && _myReview == null)
              Container(
                padding: const EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .color!
                      .withOpacity(0.04),
                  borderRadius:
                  BorderRadius.circular(defaultBorderRadious),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Write a Review",
                      style:
                      Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      itemCount: 5,
                      itemBuilder: (_, __) =>
                      const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (v) =>
                          setState(() => _rating = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Share your experience...",
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                        _submitting ? null : _submitReview,
                        child: _submitting
                            ? const CircularProgressIndicator()
                            : const Text("Submit Review"),
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


////////////////////////////////////////////////////////////////
/// RATING SUMMARY
////////////////////////////////////////////////////////////////
class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.avgRating,
    required this.totalReviews,
    required this.starCount,
  });

  final double avgRating;
  final int totalReviews;
  final Map<int, int> starCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .textTheme
            .bodyLarge!
            .color!
            .withOpacity(0.04),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                RatingBarIndicator(
                  rating: avgRating,
                  itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 22,
                ),
                Text("Based on $totalReviews reviews"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// REVIEW TILE
////////////////////////////////////////////////////////////////
class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final String currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.review,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = review.isMine(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (isMine)
                  PopupMenuButton<String>(
                    onSelected: (v) =>
                    v == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text("Edit")),
                      PopupMenuItem(value: 'delete', child: Text("Delete")),
                    ],
                  ),
              ],
            ),
            RatingBarIndicator(
              rating: review.rating,
              itemBuilder: (_, __) =>
              const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 18,
            ),
            if (review.comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(review.comment),
              ),
          ],
        ),
      ),
    );
  }
}
