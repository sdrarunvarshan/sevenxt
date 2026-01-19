import 'package:flutter/material.dart';import 'package:sevenext/entry_point.dart';import 'package:sevenext/route/contact_service.dart';import 'package:sevenext/route/guest_services.dart';import 'package:sevenext/route/privacy_service.dart';import 'package:sevenext/route/return_service.dart';import 'package:sevenext/route/route_constants.dart';import 'package:sevenext/route/guest_protect_route.dart';import 'package:sevenext/route/terms_service.dart';import 'package:sevenext/screens/home/views/components/category_products_screen.dart';import 'package:sevenext/screens/profile/views/help_screen.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/return_model.dart';
import '../screens/checkout/views/cart_screen.dart';
import '../screens/home/views/gadgets_screen.dart';
import '../screens/payment/views/payment_screen.dart';
import '../screens/payment/views/return_request_screen.dart';
import '../screens/order/views/order_details_screen.dart';
import '../screens/order/views/orders_conformation_screen.dart';
import 'aboutus_service.dart';
import 'grievance_service.dart';
import 'screen_export.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onbordingScreenRoute:
      return MaterialPageRoute(builder: (context) => const OnBordingScreen());
    case entryPointScreenRoute:
      final initialIndex = settings.arguments as int?;
      return MaterialPageRoute(
        builder: (context) => EntryPoint(initialIndex: initialIndex ?? 0),
      );
    case logInScreenRoute:
      return MaterialPageRoute(builder: (context) => const LoginScreen());
    case termsOfServicesScreenRoute:
      return MaterialPageRoute(builder: (context) => const TermsOfServicesScreen());
    case ReturnRefundPolicyScreenRoute:
      return MaterialPageRoute(builder: (context) => const ReturnRefundPolicyScreen());
    case grievanceRedressalScreenRoute:
      return MaterialPageRoute(builder: (context) => const GrievanceRedressalScreen());
    case aboutUsScreenRoute:
      return MaterialPageRoute(builder: (context) => const AboutUsScreen());
    case contactUsScreenRoute:
      return MaterialPageRoute(builder: (context) => const ContactUsScreen());
    case privacyPolicyScreenRoute:
      return MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen());
    case signUpScreenRoute:
      return MaterialPageRoute(builder: (context) => const SignUpScreen());
    case productReviewsScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => ProductReviewsScreen(
          product: args['product'],
        ),
      );

    case paymentScreenRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => PaymentScreen(
          selectedAddress: args?['selectedAddress'],
          shippingFee: args?['shippingFee'],
          cart: args?['cart'],
          stateGstAmount: args?['stateGstAmount'],
          centralGstAmount: args?['centralGstAmount'],
          stateGstPercent: args?['stateGstPercent'], // Pass percentage
          centralGstPercent: args?['centralGstPercent'], // Pass percentage
          userType: args?['userType'], // FIX: Pass userType to PaymentScreen
        ),
      );
    case productDetailsScreenRoute:
      final product = settings.arguments as ProductModel?;
      return MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product));
    case getHelpScreenRoute:
      return MaterialPageRoute(builder: (context) => const HelpScreen());
    case passwordRecoveryScreenRoute:
      return MaterialPageRoute(builder: (context) => const PasswordRecoveryScreen());
    case categoryProductsScreen:
      final categoryName = settings.arguments as String?;
      return MaterialPageRoute(builder: (context) => CategoryProductsScreen(categoryName: categoryName ?? 'Products', ));
    case gadgetsScreenRoute:
      return MaterialPageRoute(builder: (context) => const GadgetsScreen());
    case homeScreenRoute:
      return MaterialPageRoute(builder: (context) => const HomeScreen());
    case searchScreenRoute:
      return MaterialPageRoute(builder: (context) => const SearchScreen());
    case profileScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: profileScreenRoute, child: ProfileScreen()));
    case cartScreenRoute:
      return MaterialPageRoute( builder: (context) => const GuestProtectedRoute(routeName: cartScreenRoute,child: CartScreen()));
    case ordersScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: ordersScreenRoute, child: OrdersScreen()));
     case addressesScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: addressesScreenRoute, child: AddressesScreen(isSelectingMode: true)));
    case userInfoScreenRoute:
      return MaterialPageRoute(builder: (context) => const GuestProtectedRoute(routeName: userInfoScreenRoute, child: UserInfoScreen()));
    case returnRequestScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => ReturnRequestScreen(
          order: args['order'] as Order,
          product: args['product'] as OrderedProduct,
          initialType: args['type'] as ReturnType,
        ),
      );

    case orderConfirmationScreenRoute:
      final order = settings.arguments as Order?;
      if (order != null) {
        return MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(order: order),
        );
      }
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: Text('Order information missing')),
        ),
      );

    case orderDetailsScreenRoute:
      final orderId = settings.arguments as String?;
      if (orderId != null && orderId.isNotEmpty) {
        return MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(orderId: orderId),
        );
      }
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: Text('Order ID missing')),
        ),
      );

    default:
      return MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Page not found'))));
  }
}