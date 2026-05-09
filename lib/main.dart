import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

import 'screens/profile_setup_screen.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final userProvider = UserProvider();
  userProvider.init(); // Inizializzazione in background

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const LupusApp(),
    ),
  );
}

class LupusApp extends StatefulWidget {
  const LupusApp({super.key});

  @override
  State<LupusApp> createState() => _LupusAppState();
}

class _LupusAppState extends State<LupusApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final gameProvider = context.read<GameProvider>();
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      gameProvider.pauseLobbyMusic();
    } else if (state == AppLifecycleState.resumed) {
      gameProvider.resumeLobbyMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    
    if (!userProvider.isInitialized) {
      return MaterialApp(
        title: 'Lupus in Fabula',
        theme: AppTheme.getTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.dayBg,
          body: const Center(
            child: CircularProgressIndicator(color: AppTheme.leatherBrown),
          ),
        ),
      );
    }

    // Se l'inizializzazione è finita ma non c'è un utente (primo accesso), vai al setup
    if (userProvider.user == null) {
      return MaterialApp(
        title: 'Lupus in Fabula',
        theme: AppTheme.getTheme(),
        debugShowCheckedModeBanner: false,
        home: const ProfileSetupScreen(),
      );
    }

    return MaterialApp(
      title: 'Lupus in Fabula',
      theme: AppTheme.getTheme(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
