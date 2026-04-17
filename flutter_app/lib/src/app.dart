import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_session.dart';
import 'core/utils/app_navigator.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/startup_screen.dart';

class SmartAttendanceApp extends StatefulWidget {
  const SmartAttendanceApp({super.key});

  @override
  State<SmartAttendanceApp> createState() => _SmartAttendanceAppState();
}

class _SmartAttendanceAppState extends State<SmartAttendanceApp> {
  late final AppSession _session;

  @override
  void initState() {
    super.initState();
    _session = AppSession()..bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB),
        onPrimary: Colors.white,
        secondary: Color(0xFF4F46E5),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
    );

    return ChangeNotifierProvider<AppSession>.value(
      value: _session,
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'Smart Attendance',
        debugShowCheckedModeBanner: false,
        theme: baseTheme.copyWith(
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          ),
          dividerColor: Colors.transparent,
          splashFactory: InkSparkle.splashFactory,
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 12,
            shadowColor: const Color(0x0C0F172A),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              return GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              return IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
                size: 26,
              );
            }),
            indicatorColor: const Color(0x1A2563EB),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x332563EB),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          tabBarTheme: TabBarThemeData(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332563EB),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
        home: Consumer<AppSession>(
          builder: (context, session, _) {
            final screen = switch (session.state) {
              AppBootstrapState.loading => const StartupScreen(
                key: ValueKey('bootstrap-loading'),
              ),
              AppBootstrapState.unauthenticated => const KeyedSubtree(
                key: ValueKey('bootstrap-login'),
                child: LoginScreen(),
              ),
              AppBootstrapState.authenticated => const KeyedSubtree(
                key: ValueKey('bootstrap-shell'),
                child: AppShell(),
              ),
            };

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                );
              },
              child: screen,
            );
          },
        ),
      ),
    );
  }
}
