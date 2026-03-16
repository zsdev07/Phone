import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'services/call_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF16161F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: PhoneApp()));
}

class PhoneApp extends StatefulWidget {
  const PhoneApp({super.key});

  @override
  State<PhoneApp> createState() => _PhoneAppState();
}

class _PhoneAppState extends State<PhoneApp> {
  @override
  void initState() {
    super.initState();
    _listenCallState();
  }

  void _listenCallState() {
    CallService.callStateStream.listen((event) {
      final ctx = appRouter.routerDelegate.navigatorKey.currentContext;
      if (ctx == null) return;

      if (event.isDialing || event.isActive) {
        // Push in-call screen if not already there
        final location = appRouter.routeInformationProvider.value.uri.toString();
        if (!location.startsWith('/incall')) {
          appRouter.go('/incall', extra: {
            'number': event.number,
            'name':   '',
          });
        }
      } else if (event.isDisconnected) {
        final location = appRouter.routeInformationProvider.value.uri.toString();
        if (location.startsWith('/incall')) {
          appRouter.go('/dialpad');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Phone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppTheme.surface,
          surfaceContainer: AppTheme.surfaceContainer,
        ),
        scaffoldBackgroundColor: AppTheme.surface,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppTheme.surfaceContainer,
          indicatorColor: AppTheme.primary.withOpacity(0.2),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppTheme.primaryLight, size: 24);
            }
            return const IconThemeData(color: AppTheme.onSurfaceMuted, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600);
            }
            return const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12);
          }),
          elevation: 0,
          height: 70,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: AppTheme.onSurfaceMuted),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: AppTheme.onSurface,
          iconColor: AppTheme.onSurfaceMuted,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2A2A3E),
          thickness: 0.5,
          space: 0,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
