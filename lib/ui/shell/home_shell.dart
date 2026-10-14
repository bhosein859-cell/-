import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../features/insights/features_hub_screen.dart';
import '../screens/about_screen.dart';
import '../screens/active_projects_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/knowledge_base_screen.dart';
import '../screens/new_problem_screen.dart';
import '../screens/settings_screen.dart';

/// آیتم منوی ناوبری.
class NavigationItem {
  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// پوسته‌ی اصلی اپ با ناوبری واکنش‌گرا:
///
/// - عرض ≥ ۹۶۰ پیکسل (دسکتاپ/ویندوز): منوی کناری (Sidebar)
/// - عرض < ۹۶۰ پیکسل (موبایل/اندروید): منوی پایین (Bottom Navigation)
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const double _desktopBreakpoint = 960;
  int _selectedIndex = 0;

  static const List<NavigationItem> _items = [
    NavigationItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'داشبورد'),
    NavigationItem(
        icon: Icons.add_circle_outline,
        selectedIcon: Icons.add_circle,
        label: 'مشکل جدید'),
    NavigationItem(
        icon: Icons.folder_open_outlined,
        selectedIcon: Icons.folder_open,
        label: 'پروژه‌های فعال'),
    NavigationItem(
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome,
        label: 'ابزارهای هوشمند'),
    NavigationItem(
        icon: Icons.auto_stories_outlined,
        selectedIcon: Icons.auto_stories,
        label: 'بانک دانش'),
    NavigationItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'تنظیمات'),
    NavigationItem(
        icon: Icons.info_outline, selectedIcon: Icons.info, label: 'درباره ما'),
  ];

  Widget get _currentScreen => switch (_selectedIndex) {
        0 => const DashboardScreen(),
        1 => const NewProblemScreen(),
        2 => const ActiveProjectsScreen(),
        3 => const FeaturesHubScreen(),
        4 => const KnowledgeBaseScreen(),
        5 => const SettingsScreen(),
        _ => const AboutScreen(),
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= _desktopBreakpoint;

        final Widget content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          child: KeyedSubtree(
            key: ValueKey<int>(_selectedIndex),
            child: _currentScreen,
          ),
        );

        // ── چیدمان دسکتاپ: منوی کناری ──
        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  items: _items,
                  selectedIndex: _selectedIndex,
                  onTap: _select,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        // ── چیدمان موبایل: منوی پایین ──
        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _select,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              for (final item in _items)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
            ],
          ),
        );
      },
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}

/// منوی کناری برنددار برای دسکتاپ.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // سربرگ برند
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SvgPicture.asset('assets/images/logo.svg', width: 46, height: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'کاری از ${AppConstants.creator}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // آیتم‌های منو
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildTile(context, index),
            ),
          ),
          // پابرگ نسخه
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'نسخه‌ی ${AppConstants.appVersion} • ${AppConstants.phaseName}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, int index) {
    final theme = Theme.of(context);
    final selected = index == selectedIndex;
    final item = items[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: .10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
