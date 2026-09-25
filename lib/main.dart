import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/root_screen.dart';
import 'services/ads_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Start.io = Android uniquement : pas d'ads sur la preview web.
    AdsService.instance.init();
  }
  runApp(const SportflixApp());
}

class SportflixApp extends StatelessWidget {
  const SportflixApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sportflix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RootScreen(),
    );
  }
}
