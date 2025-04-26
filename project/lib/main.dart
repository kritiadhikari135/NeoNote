import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Import FlutterQuillLocalizations
import 'package:provider/provider.dart';
import 'package:calendar_view/calendar_view.dart';
import 'providers/pages_provider.dart';
import 'app_router.dart';
import 'personalScreen/bin.dart'; // Import BinProvider

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Get the initial route based on login status
  String initialRoute = await AppRouter.getInitialRoute();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PagesProvider()),
        ChangeNotifierProvider(create: (_) => BinProvider()),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider(
      controller: EventController(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NeoNote', // Updated title
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        supportedLocales: const [
          Locale('en'), // Add other locales if needed
        ],
        localizationsDelegates: const [
          FlutterQuillLocalizations.delegate, // Fix for FlutterQuill localization
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}