import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_page.dart';
import 'screens/start_visit_page.dart';
import 'screens/session_page.dart';
import 'screens/manual_session_page.dart';
import 'screens/completed_sessions_page.dart';
import 'screens/session_details_page.dart';
import 'screens/behaviors_page.dart';
import 'screens/mcp_test_page.dart';
import 'services/filemaker_service.dart';
import 'services/token_service.dart';
import 'providers/session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 App starting - loading Sanctum token...');
  // Load Sanctum token at app startup
  final token = await TokenService.loadSanctumToken();
  if (token != null) {
    print('✅ Sanctum token loaded at startup: ${token.length} chars');
  } else {
    print('⚠️ No Sanctum token found at startup');
  }
  
  runApp(const DataSheetsApp());
}

class DataSheetsApp extends StatelessWidget {
  const DataSheetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FileMakerService>(create: (_) => FileMakerService()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: MaterialApp(
        title: 'ABA Data Collection',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        home: const LoginPage(),
        routes: {
          '/start-visit': (context) => const StartVisitPage(),
          '/session': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return SessionPage(
              visit: args?['visit'],
              client: args?['client'],
            );
          },
          '/manual-session': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return ManualSessionPage(client: args?['client']);
          },
          '/completed-sessions': (context) => const CompletedSessionsPage(),
          '/session-details': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return SessionDetailsPage(session: args?['session']);
          },
          '/behaviors': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return BehaviorsPage(
              clientId: args?['clientId'],
              visitId: args?['visitId'],
            );
          },
          '/mcp-test': (context) => const MCPTestPage(),
        },
      ),
    );
  }
}
