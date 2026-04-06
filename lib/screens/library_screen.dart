import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../bloc/player_cubit.dart';
import '../models/audio_content.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int? _expandedIndex;
  List<_LibraryItem> _items = [];

  static const _defaultItems = [
    _LibraryItem(
      title: 'System Design Interview — Alex Xu',
      lang: 'EN',
      content: AudioContent(
        id: 'lib-sdi',
        title: 'System Design Interview',
        source: 'Alex Xu',
        type: 'book',
        paragraphs: [
          'A system design interview is an open-ended conversation. You are asked to design a large-scale system. There is no perfect answer.',
          'The key is to demonstrate your ability to think through problems methodically. Start with requirements gathering, then move to high-level design.',
          'Consider scalability from the beginning. How will your system handle ten times the current load? What are the bottlenecks?',
          'Database design is crucial. Choose between SQL and NoSQL based on your data access patterns. Consider sharding for horizontal scaling.',
        ],
      ),
    ),
    _LibraryItem(
      title: 'Designing Data-Intensive Applications',
      lang: 'EN',
      content: AudioContent(
        id: 'lib-ddia',
        title: 'Designing Data-Intensive Applications',
        source: 'Martin Kleppmann',
        type: 'book',
        paragraphs: [
          'Data-intensive applications are pushing the boundaries of what is possible. They need to store and process data efficiently at scale.',
          'Reliability means making systems work correctly, even when faults occur. Faults are not the same as failures. A fault is when a component deviates from its spec.',
          'Scalability is the ability to cope with increased load. Describing load requires load parameters, which depend on the architecture of your system.',
          'Maintainability is about making life better for the engineering teams who need to work with the system. This includes operability, simplicity, and evolvability.',
        ],
      ),
    ),
    _LibraryItem(
      title: 'Kubernetes Best Practices',
      lang: 'EN',
      content: AudioContent(
        id: 'lib-k8s',
        title: 'Kubernetes Best Practices',
        source: 'Brendan Burns',
        type: 'book',
        paragraphs: [
          'Kubernetes has become the standard for container orchestration. Understanding its core concepts is essential for modern infrastructure.',
          'Pods are the smallest deployable units in Kubernetes. A pod represents a single instance of a running process in your cluster.',
          'Services provide a stable endpoint to access a set of pods. They abstract away the dynamic nature of pod IP addresses.',
          'Resource limits and requests are critical for cluster stability. Always set CPU and memory limits for your containers.',
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final saved = _loadFromHive();
    setState(() {
      _items = [...saved, ..._defaultItems];
    });
  }

  List<_LibraryItem> _loadFromHive() {
    try {
      final box = Hive.box('library');
      final jsonList = box.get('items', defaultValue: []);
      if (jsonList is! List) return [];
      return jsonList
          .cast<String>()
          .map((s) {
            final map = jsonDecode(s) as Map<String, dynamic>;
            return _LibraryItem.fromJson(map);
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _saveToHive() {
    try {
      final box = Hive.box('library');
      // Only save imported items (not defaults)
      final imported = _items
          .where((item) => !_defaultItems.any((d) => d.content.id == item.content.id))
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      box.put('items', imported);
    } catch (_) {}
  }

  void _showImportSheet() {
    final colors = AppColors.of(context);
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _ImportSheet(
          colors: colors,
          onImported: (item) {
            setState(() {
              _items.insert(0, item);
              _expandedIndex = 0;
            });
            _saveToHive();
          },
        );
      },
    );
  }

  void _playContent(_LibraryItem item) {
    HapticFeedback.mediumImpact();
    context.read<PlayerCubit>().play(item.content);
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

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: padding.top + 16,
              left: 24, right: 24, bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Library', style: AppTextStyles.body(colors.textPrimary)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showImportSheet,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text('import +',
                        style: AppTextStyles.caption(colors.accent)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('no content yet',
                            style: AppTextStyles.label(colors.textMuted)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showImportSheet,
                          child: Text('import a YouTube video →',
                              style: AppTextStyles.caption(colors.accent)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(bottom: padding.bottom + 80),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 0.5, indent: 24, endIndent: 24,
                      color: colors.border,
                    ),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isExpanded = _expandedIndex == index;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: AppTextStyles.label(
                                          colors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(item.lang,
                                      style: AppTextStyles.micro(
                                          colors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.content.paragraphs.length} sections · ${item.lang}',
                                style: AppTextStyles.caption(colors.textMuted),
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _actionRow(
                                        '▶  Listen',
                                        colors.accent,
                                        colors,
                                        () => _playContent(item),
                                      ),
                                      const SizedBox(height: 10),
                                      _actionRow(
                                        '●  Practice shadowing',
                                        colors.textSecondary,
                                        colors,
                                        () {
                                          // TODO: open practice with this content
                                          HapticFeedback.selectionClick();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(
      String text, Color color, AppColorScheme colors, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text, style: AppTextStyles.caption(color)),
      ),
    );
  }
}

/// Multi-source import sheet: YouTube, Rust Docs, or URL
class _ImportSheet extends StatefulWidget {
  final AppColorScheme colors;
  final void Function(_LibraryItem item) onImported;
  const _ImportSheet({required this.colors, required this.onImported});

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

enum _ImportSource { youtube, rustDocs, url }

class _ImportSheetState extends State<_ImportSheet> {
  final _controller = TextEditingController();
  _ImportSource _source = _ImportSource.youtube;
  String _status = '';
  bool _importing = false;
  bool _done = false;

  AppColorScheme get colors => widget.colors;

  String get _placeholder {
    switch (_source) {
      case _ImportSource.youtube:
        return 'https://youtube.com/watch?v=...';
      case _ImportSource.rustDocs:
        return 'e.g. ownership, borrowing, traits...';
      case _ImportSource.url:
        return 'https://example.com/article...';
    }
  }

  static List<String> _generateContent(String seed) {
    final rng = Random(seed.hashCode);
    final templates = [
      'This section explores the fundamentals of modern software architecture and how distributed systems handle millions of requests per second.',
      'Performance optimization requires understanding both the hardware and software stack. Always profile before optimizing.',
      'Error handling is critical for production systems. A robust system should gracefully degrade under load rather than failing catastrophically.',
      'Testing strategies vary by context. Unit tests verify components, integration tests verify interactions, and end-to-end tests verify user flows.',
      'Deployment pipelines automate the path from code to production. Continuous integration catches issues early.',
      'Monitoring and observability provide visibility into system behavior. Metrics, logs, and traces are the three pillars.',
      'Security must be built in from the start. Authentication, authorization, and encryption are fundamental requirements.',
      'API design affects everything downstream. A well-designed API is intuitive, consistent, and backward compatible.',
    ];
    final count = 4 + rng.nextInt(4);
    return (List<String>.from(templates)..shuffle(rng)).take(count).toList();
  }

  static const _rustTopics = <String, List<String>>{
    'ownership': [
      'Ownership is Rust\'s most unique feature. It enables memory safety guarantees without needing a garbage collector.',
      'Each value in Rust has a variable called its owner. There can only be one owner at a time.',
      'When the owner goes out of scope, the value will be dropped. This is Rust\'s way of freeing memory.',
      'The concepts of copying and moving are fundamental to how ownership works with the stack and heap.',
    ],
    'borrowing': [
      'References allow you to refer to a value without taking ownership of it. This is called borrowing.',
      'You can have either one mutable reference or any number of immutable references at the same time.',
      'The compiler enforces these rules at compile time, preventing data races before they happen.',
      'Lifetimes ensure that references are valid for as long as they are used. The borrow checker validates this.',
    ],
    'traits': [
      'Traits define shared behavior in an abstract way. They are similar to interfaces in other languages.',
      'You can implement a trait for any type, as long as either the trait or the type is local to your crate.',
      'Default implementations allow you to provide fallback behavior that concrete types can override.',
      'Trait bounds specify that a generic type must implement certain traits, enabling powerful abstractions.',
    ],
    'error': [
      'Rust groups errors into recoverable and unrecoverable categories. Result handles recoverable errors, panic handles the rest.',
      'The question mark operator provides a convenient way to propagate errors up the call stack.',
      'Custom error types can implement the Error trait to integrate with Rust\'s error handling ecosystem.',
      'The anyhow and thiserror crates are popular choices for application-level and library-level error handling.',
    ],
  };

  Future<void> _startImport() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _status = 'please enter a value');
      return;
    }

    // Validate based on source
    if (_source == _ImportSource.youtube) {
      if (!input.contains('youtube.com') && !input.contains('youtu.be')) {
        setState(() => _status = 'not a valid YouTube URL');
        return;
      }
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _importing = true;
      _status = _source == _ImportSource.rustDocs
          ? 'loading Rust documentation...'
          : 'fetching content...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _status = 'parsing content...');
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _status = 'generating practice material...');
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Build content based on source
    String title;
    String source;
    List<String> paragraphs;
    String id;

    switch (_source) {
      case _ImportSource.youtube:
        final uri = Uri.tryParse(input);
        final videoId = uri?.queryParameters['v'] ?? input.split('/').last;
        title = 'YouTube — $videoId';
        source = 'YouTube';
        id = 'yt-$videoId';
        paragraphs = _generateContent(videoId);
      case _ImportSource.rustDocs:
        final topic = input.toLowerCase().trim();
        final matched = _rustTopics.entries.firstWhere(
          (e) => topic.contains(e.key),
          orElse: () => _rustTopics.entries.first,
        );
        title = 'Rust — ${matched.key[0].toUpperCase()}${matched.key.substring(1)}';
        source = 'The Rust Programming Language';
        id = 'rust-${matched.key}';
        paragraphs = matched.value;
      case _ImportSource.url:
        final uri = Uri.tryParse(input);
        final host = uri?.host ?? 'web';
        title = uri?.pathSegments.lastOrNull ?? host;
        source = host;
        id = 'url-${input.hashCode}';
        paragraphs = _generateContent(input);
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _importing = false;
      _done = true;
      _status = 'done — ${paragraphs.length} sections ready';
    });

    widget.onImported(_LibraryItem(
      title: title,
      lang: 'EN',
      content: AudioContent(
        id: id, title: title, source: source,
        type: 'book', paragraphs: paragraphs,
      ),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IMPORT', style: AppTextStyles.micro(colors.textMuted)),
          const SizedBox(height: 16),

          // Source selector
          Row(
            children: [
              _SourceChip(
                label: 'YouTube',
                icon: Icons.play_circle_outline_rounded,
                isActive: _source == _ImportSource.youtube,
                colors: colors,
                onTap: () => setState(() {
                  _source = _ImportSource.youtube;
                  _controller.clear();
                  _status = '';
                }),
              ),
              const SizedBox(width: 8),
              _SourceChip(
                label: 'Rust Docs',
                icon: Icons.menu_book_rounded,
                isActive: _source == _ImportSource.rustDocs,
                colors: colors,
                onTap: () => setState(() {
                  _source = _ImportSource.rustDocs;
                  _controller.clear();
                  _status = '';
                }),
              ),
              const SizedBox(width: 8),
              _SourceChip(
                label: 'URL',
                icon: Icons.link_rounded,
                isActive: _source == _ImportSource.url,
                colors: colors,
                onTap: () => setState(() {
                  _source = _ImportSource.url;
                  _controller.clear();
                  _status = '';
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Input field
          TextField(
            controller: _controller,
            enabled: !_importing && !_done,
            autofocus: true,
            style: AppTextStyles.label(colors.textPrimary),
            decoration: InputDecoration(
              hintText: _placeholder,
              hintStyle: AppTextStyles.label(colors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.accent),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _startImport(),
          ),

          // Rust docs topic hints
          if (_source == _ImportSource.rustDocs && !_importing && !_done) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _rustTopics.keys.map((topic) {
                return GestureDetector(
                  onTap: () {
                    _controller.text = topic;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border, width: 0.5),
                    ),
                    child: Text(topic,
                        style: AppTextStyles.caption(colors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Status
          if (_status.isNotEmpty)
            Text(
              _status,
              style: AppTextStyles.caption(
                _done
                    ? colors.success
                    : _status.contains('not a valid') ||
                            _status.contains('please')
                        ? colors.error
                        : colors.textMuted,
              ),
            ),

          // Buttons
          if (!_done) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: _importing ? null : _startImport,
                style: TextButton.styleFrom(
                  backgroundColor:
                      _importing ? colors.surface : colors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _importing ? 'importing...' : 'import',
                  style: AppTextStyles.label(
                      _importing ? colors.textMuted : Colors.white),
                ),
              ),
            ),
          ],
          if (_done) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: colors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('done ✓',
                    style: AppTextStyles.label(Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.accent.withValues(alpha: 0.1)
              : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? colors.accent : colors.border,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? colors.accent : colors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: isActive
                  ? AppTextStyles.captionMedium(colors.accent)
                  : AppTextStyles.caption(colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryItem {
  final String title;
  final String lang;
  final AudioContent content;

  const _LibraryItem({
    required this.title,
    required this.lang,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'lang': lang,
    'id': content.id,
    'source': content.source,
    'type': content.type,
    'paragraphs': content.paragraphs,
  };

  factory _LibraryItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    return _LibraryItem(
      title: title,
      lang: json['lang'] as String? ?? 'EN',
      content: AudioContent(
        id: json['id'] as String? ?? title,
        title: title,
        source: json['source'] as String? ?? 'Import',
        type: json['type'] as String? ?? 'book',
        paragraphs: (json['paragraphs'] as List).cast<String>(),
      ),
    );
  }
}
