import 'package:flutter/material.dart';
import 'package:provider/provider.dart';import 'package:sevenext/route/api_service.dart';import 'package:sevenext/route/route_constants.dart';import 'package:sevenext/route/router.dart' as router;import 'package:sevenext/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';import 'package:sevenext/route/guest_services.dart';
import '/screens/discover/category_images_provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        title: 'sevenext Template by The Flutter Way',
        theme: AppTheme.lightTheme(context),
        themeMode: ThemeMode.light,
        onGenerateRoute: router.generateRoute,
        initialRoute: onbordingScreenRoute,
      ),
    );
  }
}