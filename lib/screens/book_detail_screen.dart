import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/player_cubit.dart';
import '../models/audio_content.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'player_screen.dart';

/// Book detail screen — shows cover, metadata, chapters, and "Start reading" CTA.
class BookDetailScreen extends StatelessWidget {
  final AudioContent content;

  const BookDetailScreen({super.key, required this.content});

  void _startReading(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.read<PlayerCubit>().play(content);
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
    final colors = AppColors.of(context);
    final padding = MediaQuery.of(context).padding;
    final topPad = Platform.isMacOS ? 38.0 : padding.top;
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      body: Column(
        children: [
          // Top bar
          Padding(
            padding: EdgeInsets.only(
              top: topPad + 8,
              left: Platform.isMacOS ? 80 : 24,
              right: 24,
              bottom: 8,
            ),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go('/library'),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text('←',
                        style: AppTextStyles.label(colors.textPrimary)),
                  ),
                ),
                Text('Book Detail',
                    style: AppTextStyles.caption(colors.textMuted)),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 24,
                vertical: 24,
              ),
              child: isWide
                  ? _buildWideLayout(context, colors)
                  : _buildNarrowLayout(context, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, AppColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: cover placeholder
        _BookCover(colors: colors, title: content.title),
        const SizedBox(width: 48),
        // Right: details
        Expanded(child: _buildDetails(context, colors)),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.03, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildNarrowLayout(BuildContext context, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _BookCover(colors: colors, title: content.title)),
        const SizedBox(height: 32),
        _buildDetails(context, colors),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.03, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildDetails(BuildContext context, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          content.title,
          style: GoogleFonts.sourceSerif4(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        // Author/source
        Text(
          content.source,
          style: AppTextStyles.label(colors.textSecondary),
        ),
        const SizedBox(height: 16),
        // Description
        Text(
          content.paragraphs.isNotEmpty ? content.paragraphs.first : '',
          style: AppTextStyles.caption(colors.textMuted).copyWith(height: 1.7),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 24),

        // Action row
        Row(
          children: [
            // Start reading button
            GestureDetector(
              onTap: () => _startReading(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Start reading',
                        style: AppTextStyles.captionMedium(Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Bookmark icon
            _IconBtn(
              icon: Icons.bookmark_outline_rounded,
              colors: colors,
              onTap: () => HapticFeedback.selectionClick(),
            ),
            const SizedBox(width: 8),
            _IconBtn(
              icon: Icons.share_outlined,
              colors: colors,
              onTap: () => HapticFeedback.selectionClick(),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Metadata section
        _metaSection('Sections', '${content.paragraphs.length} parts', colors),
        const SizedBox(height: 16),
        _metaSection('Language', 'English (US & UK)', colors),
        const SizedBox(height: 16),
        _metaSection('Type',
            content.type == 'book' ? 'Book / Documentation' : 'News Article',
            colors),

        const SizedBox(height: 40),

        // Chapters / sections list
        Text('CONTENTS',
            style: AppTextStyles.micro(colors.textMuted)
                .copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 16),
        ...content.paragraphs.asMap().entries.map((e) {
          final idx = e.key;
          final para = e.value;
          final preview = para.length > 60
              ? '${para.substring(0, 60)}...'
              : para;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                context.read<PlayerCubit>().play(content, fromSentence: idx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: colors.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const PlayerScreen(),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${idx + 1}',
                        style: AppTextStyles.caption(colors.accent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        preview,
                        style: AppTextStyles.caption(colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded,
                        size: 18, color: colors.textMuted),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _metaSection(String label, String value, AppColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: AppTextStyles.caption(colors.textMuted)
                  .copyWith(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child:
              Text(value, style: AppTextStyles.caption(colors.textSecondary)),
        ),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  final AppColorScheme colors;
  final String title;

  const _BookCover({required this.colors, required this.title});

  @override
  Widget build(BuildContext context) {
    // Gradient placeholder for book cover
    return Container(
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accent.withValues(alpha: 0.3),
            colors.accent.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sourceSerif4(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: colors.textSecondary),
      ),
    );
  }
}
