import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/app_env.dart';
import 'core/token_storage.dart';
import 'models/de_thi.dart';
import 'providers/auth_provider.dart';
import 'providers/binh_luan_provider.dart';
import 'providers/cau_hoi_provider.dart';
import 'providers/chu_de_provider.dart';
import 'providers/de_thi_provider.dart';
import 'providers/ket_qua_thi_provider.dart';
import 'providers/lien_he_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/thi_provider.dart';
import 'providers/users_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/two_fa_login_screen.dart';
import 'screens/quiz_screen.dart';
import 'services/binh_luan_service.dart';
import 'services/cau_hoi_service.dart';
import 'services/chu_de_service.dart';
import 'services/de_thi_service.dart';
import 'services/ket_qua_thi_service.dart';
import 'services/lien_he_service.dart';
import 'services/chat_service.dart';
import 'services/thi_service.dart';
import 'services/users_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load .env
  final apiClient = ApiClient(baseUrl: AppEnv.baseUrl);
  final tokenStorage = TokenStorage();
  runApp(MyApp(apiClient: apiClient, tokenStorage: tokenStorage));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  const MyApp({super.key, required this.apiClient, required this.tokenStorage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<TokenStorage>.value(value: tokenStorage),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) {
            final provider = AuthProvider(
              apiClient: apiClient,
              tokenStorage: tokenStorage,
            );
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => DeThiProvider(DeThiService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => ChuDeProvider(ChuDeService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => CauHoiProvider(CauHoiService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => ThiProvider(ThiService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => KetQuaThiProvider(KetQuaThiService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => BinhLuanProvider(BinhLuanService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => LienHeProvider(LienHeService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(UsersService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(ChatService(apiClient)),
        ),
      ],
      child: MaterialApp(
        title: 'Thi Trắc Nghiệm App',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Dismiss keyboard when tapping outside and ensure consistent scroll behavior
          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: child ?? const SizedBox.shrink(),
          );
        },
        theme: ThemeData(
          useMaterial3: true, // Giao diện Material 3 đẹp
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/home') {
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          }
          if (settings.name == '/login-2fa') {
            return MaterialPageRoute(builder: (_) => const TwoFaLoginScreen());
          }
          if (settings.name == '/quiz') {
            final args = settings.arguments;
            if (args is DeThi) {
              return MaterialPageRoute(builder: (_) => QuizScreen(deThi: args));
            }
            // If arguments are missing or wrong type, fall back to home
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          }
          return null;
        },
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isInitialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return auth.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
