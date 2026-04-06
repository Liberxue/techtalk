import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/audio_content.dart';

/// Abstracts Hive persistence for the user's library.
class LibraryRepository {
  static const _boxName = 'library';
  static const _key = 'items';

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Load all user-imported library items from Hive.
  List<LibraryItem> loadItems() {
    try {
      final box = Hive.box(_boxName);
      final jsonList = box.get(_key, defaultValue: []);
      if (jsonList is! List) return [];
      return jsonList
          .cast<String>()
          .map((s) {
            final map = jsonDecode(s) as Map<String, dynamic>;
            return LibraryItem.fromJson(map);
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Persist the full list of user-imported items.
  void saveItems(List<LibraryItem> items) {
    try {
      final box = Hive.box(_boxName);
      final encoded = items.map((item) => jsonEncode(item.toJson())).toList();
      box.put(_key, encoded);
    } catch (_) {
      // Silently fail — Hive may not be open in tests.
    }
  }

  /// Add a single item and persist.
  void addItem(LibraryItem item) {
    final items = loadItems();
    items.insert(0, item);
    saveItems(items);
  }

  /// Remove an item by its content id and persist.
  void removeItem(String id) {
    final items = loadItems();
    items.removeWhere((item) => item.content.id == id);
    saveItems(items);
  }
}

/// A library entry combining metadata with playable [AudioContent].
class LibraryItem {
  final String title;
  final String lang;
  final AudioContent content;

  const LibraryItem({
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

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    return LibraryItem(
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
