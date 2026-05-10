import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/health_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/overview_provider.dart';
import 'services/notification_service.dart';
import 'pages/overview_page.dart';
import 'pages/health_page.dart';
import 'pages/schedule_page.dart';
import 'pages/settings_page.dart';
import 'utils/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  notificationService.navigatorKey = navigatorKey;
  await notificationService.initialize();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(TodoApp(
    settingsProvider: settingsProvider,
    notificationService: notificationService,
  ));
}

class TodoApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final NotificationService notificationService;

  const TodoApp({
    super.key,
    required this.settingsProvider,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => OverviewProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'TODO',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeName == 'dark'
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const MainScreen(),
            routes: {
              '/overview': (_) => const MainScreen(initialIndex: 0),
              '/health': (_) => const MainScreen(initialIndex: 1),
              '/schedule': (_) => const MainScreen(initialIndex: 2),
              '/settings': (_) => const MainScreen(initialIndex: 3),
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late int _currentIndex;
  late final List<Widget> _pages;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = const [
      OverviewPage(),
      HealthPage(),
      SchedulePage(),
      SettingsPage(),
    ];
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notificationService.requestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      context.read<OverviewProvider>().initializeToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = settings.theme;

    return Theme(
      data: theme,
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: '概览',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: '健康',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: '日程',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}
