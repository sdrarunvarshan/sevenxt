import 'dart:js' as js;

void openRazorpay({
  required Map<String, dynamic> options,
  required Function(dynamic) successCallback,
  required Function() dismissCallback,
}) {
  // Add success handler
  options['handler'] = js.allowInterop(successCallback);

  // Handle modal dismiss / cancel
  options['modal'] = {
    'ondismiss': js.allowInterop(dismissCallback),
  };

  try {
    final jsOptions = js.JsObject.jsify(options);
    final rzp = js.JsObject(js.context['Razorpay'], [jsOptions]);
    rzp.callMethod('open');
  } catch (e) {
    // Handle error (you can pass this back if needed, but for now, log and rethrow)
    print("Razorpay web open error: $e");
    rethrow;
  }
}