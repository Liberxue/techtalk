import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/audio_content.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class _BookItem {
  final String title;
  final String source;
  final Color color;
  final AudioContent content;

  const _BookItem({
    required this.title,
    required this.source,
    required this.color,
    required this.content,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _books = [
    _BookItem(
      title: 'Designing Data-Intensive Apps',
      source: 'Martin Kleppmann',
      color: Color(0xFF4D8FFF),
      content: AudioContent(
        id: 'home-ddia', title: 'Designing Data-Intensive Applications',
        source: 'Martin Kleppmann', type: 'book',
        paragraphs: [
          'Data-intensive applications are pushing the boundaries of what is possible. They need to store and process data efficiently at scale.',
          'Reliability means making systems work correctly, even when faults occur. Faults are not the same as failures.',
          'Scalability is the ability to cope with increased load. Describing load requires load parameters specific to your architecture.',
          'Maintainability is about making life better for engineering teams. This includes operability, simplicity, and evolvability.',
        ],
      ),
    ),
    _BookItem(
      title: 'Clean Architecture',
      source: 'Robert C. Martin',
      color: Color(0xFF00C48C),
      content: AudioContent(
        id: 'home-clean', title: 'Clean Architecture',
        source: 'Robert C. Martin', type: 'book',
        paragraphs: [
          'The goal of software architecture is to minimize the human resources required to build and maintain the system.',
          'Good architecture makes the system easy to understand, easy to develop, easy to maintain, and easy to deploy.',
          'The dependency rule states that source code dependencies must point only inward, toward higher-level policies.',
          'Business rules are the critical rules that make or save money, whether automated or manual.',
        ],
      ),
    ),
    _BookItem(
      title: 'The Pragmatic Programmer',
      source: 'Hunt & Thomas',
      color: Color(0xFFD97706),
      content: AudioContent(
        id: 'home-pragmatic', title: 'The Pragmatic Programmer',
        source: 'Hunt & Thomas', type: 'book',
        paragraphs: [
          'Care about your craft. Why spend your life developing software unless you care about doing it well?',
          'Provide options, not excuses. Instead of giving reasons why something cannot be done, explain what can be done.',
          'Do not live with broken windows. Fix bad designs, wrong decisions, and poor code when you see them.',
          'Be a catalyst for change. You cannot force change on people. Show them how the future might be, and help them participate.',
        ],
      ),
    ),
    _BookItem(
      title: 'Refactoring',
      source: 'Martin Fowler',
      color: Color(0xFFD93025),
      content: AudioContent(
        id: 'home-refactor', title: 'Refactoring',
        source: 'Martin Fowler', type: 'book',
        paragraphs: [
          'Refactoring is a controlled technique for improving the design of an existing code base without changing its behavior.',
          'The key insight is that small changes accumulate. Each individual refactoring is small, but together they can restructure a system.',
          'When you need to add a feature and the code is not structured conveniently, first refactor so the change is easy, then make the easy change.',
          'Good tests are essential for refactoring. Without them you cannot be confident that your changes preserve behavior.',
        ],
      ),
    ),
    _BookItem(
      title: 'Domain-Driven Design',
      source: 'Eric Evans',
      color: Color(0xFF7C3AED),
      content: AudioContent(
        id: 'home-ddd', title: 'Domain-Driven Design',
        source: 'Eric Evans', type: 'book',
        paragraphs: [
          'Domain-driven design focuses on the core domain and domain logic. It bases complex designs on a model of the domain.',
          'A ubiquitous language is a common language shared by developers and domain experts to eliminate miscommunication.',
          'Bounded contexts define the boundaries within which a model applies. Different contexts may use different models for the same concept.',
          'Aggregates are clusters of objects treated as a single unit for data changes. They ensure consistency within the boundary.',
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final padding = MediaQuery.of(context).padding;
    final topPad = Platform.isMacOS ? 38.0 : padding.top;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: topPad + 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _MainColumn(colors: colors, books: _books),
                  ),
                  SizedBox(
                    width: constraints.maxWidth * 0.4,
                    child: _RightPanel(colors: colors),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MainColumn(colors: colors, books: _books),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _RightPanel(colors: colors),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Column (left side)
// ---------------------------------------------------------------------------
class _MainColumn extends StatelessWidget {
  final AppColorScheme colors;
  final List<_BookItem> books;

  const _MainColumn({required this.colors, required this.books});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimateList(
          interval: 80.ms,
          effects: [
            FadeEffect(duration: 350.ms, curve: Curves.easeOut),
            SlideEffect(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
              duration: 350.ms,
              curve: Curves.easeOutCubic,
            ),
          ],
          children: [
            // Greeting
            Text(
              'Happy reading',
              style: GoogleFonts.sourceSerif4(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              'Continue where you left off. Your practice streak is growing.',
              style: AppTextStyles.caption(colors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Start practice button
            SizedBox(
              width: 160,
              height: 44,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/practice');
                },
                style: TextButton.styleFrom(
                  backgroundColor: colors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Start practice \u2192',
                  style: AppTextStyles.caption(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Popular Now label
            Text(
              'POPULAR NOW',
              style: AppTextStyles.micro(colors.textMuted).copyWith(
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal book row
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return _BookCard(book: book, colors: colors);
                },
              ),
            ),
            const SizedBox(height: 24),

            // Recent Sessions label
            Text(
              'RECENT SESSIONS',
              style: AppTextStyles.micro(colors.textMuted).copyWith(
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Stat rows
            _StatRow(
              label: 'Avg Score',
              value: '81/100',
              colors: colors,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Sessions',
              value: '47',
              colors: colors,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Weak Words',
              value: '3',
              colors: colors,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right Panel
// ---------------------------------------------------------------------------
class _RightPanel extends StatelessWidget {
  final AppColorScheme colors;

  const _RightPanel({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currently Reading label
            Text(
              'CURRENTLY READING',
              style: AppTextStyles.micro(colors.textMuted).copyWith(
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Currently reading card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Design Interview',
                    style: AppTextStyles.headline(colors.textPrimary).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alex Xu',
                    style: AppTextStyles.caption(colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '2 / 4 sections',
                    style: AppTextStyles.caption(colors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: colors.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colors.accent),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.go('/library'),
                    child: Text(
                      'Continue reading \u2192',
                      style: AppTextStyles.caption(colors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats label
            Text(
              'QUICK STATS',
              style: AppTextStyles.micro(colors.textMuted).copyWith(
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Stat pills row
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    value: '12',
                    label: 'streak',
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    value: '2840',
                    label: 'xp',
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    value: '81',
                    label: 'avg',
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book Card
// ---------------------------------------------------------------------------
class _BookCard extends StatelessWidget {
  final _BookItem book;
  final AppColorScheme colors;

  const _BookCard({required this.book, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go('/book/${book.content.id}', extra: book.content);
      },
      child: Container(
        width: 115,
        height: 155,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              book.color.withValues(alpha: 0.8),
              book.color.withValues(alpha: 0.4),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: book.color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              book.title,
              style: GoogleFonts.sourceSerif4(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              book.source,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Row (for Recent Sessions)
// ---------------------------------------------------------------------------
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColorScheme colors;

  const _StatRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.caption(colors.textMuted)),
        ),
        Text(value, style: AppTextStyles.label(colors.textPrimary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Pill (for Quick Stats)
// ---------------------------------------------------------------------------
class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final AppColorScheme colors;

  const _StatPill({
    required this.value,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headline(colors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption(colors.textMuted)),
        ],
      ),
    );
  }
}
