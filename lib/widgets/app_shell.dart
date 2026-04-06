import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/mini_player.dart';
import '../screens/player_screen.dart';

/// Responsive navigation shell.
///
/// * Narrow (< 600 px): child + MiniPlayer + AppBottomNav at the bottom.
/// * Wide  (>= 600 px): fixed icon-only sidebar on the left + child filling the rest.
class AppShell extends StatelessWidget {
  final String currentRoute;
  final Widget child;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  static const _tabs = [
    ('Practice', '/', Icons.mic_none_rounded),
    ('Library', '/library', Icons.folder_open_rounded),
    ('Progress', '/progress', Icons.bar_chart_rounded),
    ('Settings', '/settings', Icons.settings_outlined),
  ];

  static const double _sidebarWidth = 72;
  static const double _breakpoint = 600;

  void _openPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.of(context).background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PlayerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _breakpoint;

        if (isWide) {
          return _buildWideLayout(context);
        }
        return _buildNarrowLayout(context);
      },
    );
  }

  // ── Narrow: mobile layout (child + mini player + bottom nav) ──────────

  Widget _buildNarrowLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          MiniPlayer(onTap: () => _openPlayer(context)),
          AppBottomNav(currentRoute: currentRoute),
        ],
      ),
    );
  }

  // ── Wide: icon-only sidebar + content ─────────────────────────────────

  Widget _buildWideLayout(BuildContext context) {
    final colors = AppColors.of(context);
    // On macOS, leave space for traffic lights (≈52px from top)
    final topInset = Platform.isMacOS ? 52.0 : MediaQuery.of(context).padding.top + 24;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar — icon-only, surface background, extends to window top
          Container(
            width: _sidebarWidth,
            color: colors.surface,
            child: Column(
              children: [
                // Traffic lights area (macOS) / status bar area (iPad)
                SizedBox(height: topInset),

                // Logo monogram
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'T',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Nav items (all except Settings)
                ..._tabs
                    .where((t) => t.$2 != '/settings')
                    .map((tab) => _SidebarItem(
                          icon: tab.$3,
                          route: tab.$2,
                          isActive: currentRoute == tab.$2,
                          colors: colors,
                        )),

                const Spacer(),

                // Settings pinned at bottom
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  route: '/settings',
                  isActive: currentRoute == '/settings',
                  colors: colors,
                ),

                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16,
                ),
              ],
            ),
          ),

          // Subtle right border
          Container(width: 0.5, color: colors.border),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top padding for macOS title bar area
                if (Platform.isMacOS)
                  SizedBox(height: topInset - 20),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single sidebar navigation item (icon-only).
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String route;
  final bool isActive;
  final AppColorScheme colors;

  const _SidebarItem({
    required this.icon,
    required this.route,
    required this.isActive,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!isActive) {
              HapticFeedback.selectionClick();
              context.go(route);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive
                  ? colors.accent.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? colors.accent : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
