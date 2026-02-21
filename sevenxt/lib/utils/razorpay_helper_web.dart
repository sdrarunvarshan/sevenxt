import 'dart:js_util' as js_util;

void openRazorpay({
  required Map<String, dynamic> options,
  required Function(dynamic) successCallback,
  required Function() dismissCallback,
}) {
  // 1. Create the success handler
  // We wrap the callback to convert the JS object into a Dart Map
  // This prevents the "NoSuchMethodError: '[]'" in payment_screen.dart
  final Function wrapperSuccessCallback =
      js_util.allowInterop((dynamic response) {
    final Map<String, dynamic> responseMap = {
      'razorpay_payment_id':
          js_util.getProperty(response, 'razorpay_payment_id'),
      'razorpay_order_id': js_util.getProperty(response, 'razorpay_order_id'),
      'razorpay_signature': js_util.getProperty(response, 'razorpay_signature'),
    };
    successCallback(responseMap);
  });

  // 2. Prepare the options for JS
  // We manually set the handler and modal to ensure interop works
  options['handler'] = wrapperSuccessCallback;
  options['modal'] = {
    'ondismiss': js_util.allowInterop(dismissCallback),
  };

  try {
    // Convert the Dart Map to a JS Object
    final jsOptions = js_util.jsify(options);

    // Get the 'Razorpay' constructor from the browser's global window
    final rzpConstructor = js_util.getProperty(js_util.globalThis, 'Razorpay');

    // Create the instance: new Razorpay(jsOptions)
    final rzp = js_util.callConstructor(rzpConstructor, [jsOptions]);

    // Call the .open() method
    js_util.callMethod(rzp, 'open', []);
  } catch (e) {
    print("Razorpay web open error: $e");
  }
}
