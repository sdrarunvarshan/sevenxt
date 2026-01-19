void openRazorpay({
  required Map<String, dynamic> options,
  required Function(dynamic) successCallback,
  required Function() dismissCallback,
}) {
  // This should never be called on mobile (guarded by kIsWeb), but throw if it is
  throw UnsupportedError('Razorpay web logic is not supported on this platform');
}