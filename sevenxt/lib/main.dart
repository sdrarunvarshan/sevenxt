import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/guest_services.dart';
import 'package:sevenxt/route/route_constants.dart';
import 'package:sevenxt/route/router.dart' as router;
import 'package:sevenxt/screens/helpers/user_helper.dart';
import 'package:sevenxt/theme/app_theme.dart';

import '/screens/discover/category_images_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserHelper.init();
  await Hive.initFlutter();
  await Hive.openBox('auth');
  await Hive.openBox('user_settings');

  final token = Hive.box('auth').get('token');

  if (token != null) {
    ApiService.token = token; // IMPORTANT
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GuestService()),
        ChangeNotifierProvider(create: (_) => CategoryImagesProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'sevenxt app',
        theme: AppTheme.lightTheme(context),
        themeMode: ThemeMode.light,
        onGenerateRoute: router.generateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// NEW: SplashScreen for auth check and routing
class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime? _lastAuthCheck;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastAuthCheck == null ||
          now.difference(_lastAuthCheck!).inMinutes > 5) {
        _lastAuthCheck = now;
        _checkAuthAndNavigate();
      }
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final authBox = Hive.box('auth');
    final token = authBox.get('token');
    final isGuest = authBox.get('is_guest'); // Don't use defaultValue here!
    final hasSeenOnboarding =
        authBox.get('has_seen_onboarding', defaultValue: false);

    // Only logout if token is missing OR is_guest is explicitly set to true
    // If is_guest is null (never set), AND token exists, user is logged in
    if (token == null || isGuest == true) {
      _forceLogout(hasSeenOnboarding);
      return;
    }

    ApiService.token = token; // 🔴 VERY IMPORTANT

    final userType = await UserHelper.getUserType();

    if (userType == UserHelper.b2c) {
      final savedIndex =
          Hive.box('user_settings').get('last_tab_index', defaultValue: 0);
      Navigator.pushReplacementNamed(context, entryPointScreenRoute,
          arguments: savedIndex);
      return;
    }

    // B2B flow - check approval status
    bool isApproved = authBox.get('is_approved', defaultValue: false);

    try {
      final profile = await ApiService.getUserProfile();
      final status = profile['status']?.toString().toLowerCase() ?? 'pending';
      isApproved = status == 'approved';
      await authBox.put('is_approved', isApproved);
    } catch (e) {
      // Network error or API error - use cached approval status
      // Don't logout user just because network is unavailable!
      print('Profile fetch failed (using cached status): $e');
    }
    if (isApproved) {
      // Load saved index and navigate with arguments
      final savedIndex =
          Hive.box('user_settings').get('last_tab_index', defaultValue: 0);
      Navigator.pushReplacementNamed(context, entryPointScreenRoute,
          arguments: savedIndex);
    } else {
      Navigator.pushReplacementNamed(context, b2bApprovalPendingRoute);
    }
  }

  void _forceLogout(bool hasSeenOnboarding) async {
    final authBox = Hive.box('auth');
    // Preserve has_seen_onboarding, clear everything else
    await authBox.delete('token');
    await authBox.delete('is_guest');
    await authBox.delete('user_email');
    await authBox.delete('user_phone');
    await authBox.delete('user_name');
    await authBox.delete('is_approved');
    // Keep has_seen_onboarding!

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      hasSeenOnboarding ? logInScreenRoute : onbordingScreenRoute,
    );
  }

  void _safeNavigate(String route) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
