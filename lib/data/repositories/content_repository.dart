import 'dart:math';

import '../../models/audio_content.dart';

/// Centralized repository for all built-in content.
///
/// Consolidates the hardcoded book data previously spread across
/// `home_screen.dart` and `library_screen.dart`.
class ContentRepository {
  // ---------------------------------------------------------------------------
  // Home-screen books (5)
  // ---------------------------------------------------------------------------
  List<BookContent> getHomeBooks() {
    return const [
      BookContent(
        id: 'home-ddia',
        title: 'Designing Data-Intensive Apps',
        source: 'Martin Kleppmann',
        type: 'book',
        colorValue: 0xFF4D8FFF,
        paragraphs: [
          'Data-intensive applications are pushing the boundaries of what is possible. They need to store and process data efficiently at scale.',
          'Reliability means making systems work correctly, even when faults occur. Faults are not the same as failures.',
          'Scalability is the ability to cope with increased load. Describing load requires load parameters specific to your architecture.',
          'Maintainability is about making life better for engineering teams. This includes operability, simplicity, and evolvability.',
        ],
      ),
      BookContent(
        id: 'home-clean',
        title: 'Clean Architecture',
        source: 'Robert C. Martin',
        type: 'book',
        colorValue: 0xFF00C48C,
        paragraphs: [
          'The goal of software architecture is to minimize the human resources required to build and maintain the system.',
          'Good architecture makes the system easy to understand, easy to develop, easy to maintain, and easy to deploy.',
          'The dependency rule states that source code dependencies must point only inward, toward higher-level policies.',
          'Business rules are the critical rules that make or save money, whether automated or manual.',
        ],
      ),
      BookContent(
        id: 'home-pragmatic',
        title: 'The Pragmatic Programmer',
        source: 'Hunt & Thomas',
        type: 'book',
        colorValue: 0xFFD97706,
        paragraphs: [
          'Care about your craft. Why spend your life developing software unless you care about doing it well?',
          'Provide options, not excuses. Instead of giving reasons why something cannot be done, explain what can be done.',
          'Do not live with broken windows. Fix bad designs, wrong decisions, and poor code when you see them.',
          'Be a catalyst for change. You cannot force change on people. Show them how the future might be, and help them participate.',
        ],
      ),
      BookContent(
        id: 'home-refactor',
        title: 'Refactoring',
        source: 'Martin Fowler',
        type: 'book',
        colorValue: 0xFFD93025,
        paragraphs: [
          'Refactoring is a controlled technique for improving the design of an existing code base without changing its behavior.',
          'The key insight is that small changes accumulate. Each individual refactoring is small, but together they can restructure a system.',
          'When you need to add a feature and the code is not structured conveniently, first refactor so the change is easy, then make the easy change.',
          'Good tests are essential for refactoring. Without them you cannot be confident that your changes preserve behavior.',
        ],
      ),
      BookContent(
        id: 'home-ddd',
        title: 'Domain-Driven Design',
        source: 'Eric Evans',
        type: 'book',
        colorValue: 0xFF7C3AED,
        paragraphs: [
          'Domain-driven design focuses on the core domain and domain logic. It bases complex designs on a model of the domain.',
          'A ubiquitous language is a common language shared by developers and domain experts to eliminate miscommunication.',
          'Bounded contexts define the boundaries within which a model applies. Different contexts may use different models for the same concept.',
          'Aggregates are clusters of objects treated as a single unit for data changes. They ensure consistency within the boundary.',
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Library default books (3)
  // ---------------------------------------------------------------------------
  List<BookContent> getLibraryBooks() {
    return const [
      BookContent(
        id: 'lib-sdi',
        title: 'System Design Interview',
        source: 'Alex Xu',
        type: 'book',
        colorValue: 0xFF4D8FFF,
        paragraphs: [
          'A system design interview is an open-ended conversation. You are asked to design a large-scale system. There is no perfect answer.',
          'The key is to demonstrate your ability to think through problems methodically. Start with requirements gathering, then move to high-level design.',
          'Consider scalability from the beginning. How will your system handle ten times the current load? What are the bottlenecks?',
          'Database design is crucial. Choose between SQL and NoSQL based on your data access patterns. Consider sharding for horizontal scaling.',
        ],
      ),
      BookContent(
        id: 'lib-ddia',
        title: 'Designing Data-Intensive Applications',
        source: 'Martin Kleppmann',
        type: 'book',
        colorValue: 0xFF4D8FFF,
        paragraphs: [
          'Data-intensive applications are pushing the boundaries of what is possible. They need to store and process data efficiently at scale.',
          'Reliability means making systems work correctly, even when faults occur. Faults are not the same as failures. A fault is when a component deviates from its spec.',
          'Scalability is the ability to cope with increased load. Describing load requires load parameters, which depend on the architecture of your system.',
          'Maintainability is about making life better for the engineering teams who need to work with the system. This includes operability, simplicity, and evolvability.',
        ],
      ),
      BookContent(
        id: 'lib-k8s',
        title: 'Kubernetes Best Practices',
        source: 'Brendan Burns',
        type: 'book',
        colorValue: 0xFF00C48C,
        paragraphs: [
          'Kubernetes has become the standard for container orchestration. Understanding its core concepts is essential for modern infrastructure.',
          'Pods are the smallest deployable units in Kubernetes. A pod represents a single instance of a running process in your cluster.',
          'Services provide a stable endpoint to access a set of pods. They abstract away the dynamic nature of pod IP addresses.',
          'Resource limits and requests are critical for cluster stability. Always set CPU and memory limits for your containers.',
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // All default books (home + library, de-duplicated by id)
  // ---------------------------------------------------------------------------
  List<BookContent> getDefaultBooks() {
    final seen = <String>{};
    final all = <BookContent>[];
    for (final book in [...getHomeBooks(), ...getLibraryBooks()]) {
      if (seen.add(book.id)) {
        all.add(book);
      }
    }
    return all;
  }

  // ---------------------------------------------------------------------------
  // Rust documentation topics
  // ---------------------------------------------------------------------------
  Map<String, List<String>> getRustTopics() {
    return const {
      'ownership': [
        "Ownership is Rust's most unique feature. It enables memory safety guarantees without needing a garbage collector.",
        'Each value in Rust has a variable called its owner. There can only be one owner at a time.',
        "When the owner goes out of scope, the value will be dropped. This is Rust's way of freeing memory.",
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
        "Custom error types can implement the Error trait to integrate with Rust's error handling ecosystem.",
        'The anyhow and thiserror crates are popular choices for application-level and library-level error handling.',
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // Generate content from a seed string (for imports)
  // ---------------------------------------------------------------------------
  List<String> generateContent(String seed) {
    final rng = Random(seed.hashCode);
    const templates = [
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

  // ---------------------------------------------------------------------------
  // Convert a BookContent to AudioContent for playback
  // ---------------------------------------------------------------------------
  AudioContent toAudioContent(BookContent book) {
    return AudioContent(
      id: book.id,
      title: book.title,
      source: book.source,
      type: book.type,
      paragraphs: book.paragraphs,
    );
  }
}

/// A self-contained book content descriptor.
///
/// Similar to [AudioContent] but also carries the cover color used by the UI.
class BookContent {
  final String id;
  final String title;
  final String source;
  final String type;
  final List<String> paragraphs;
  final int colorValue;

  const BookContent({
    required this.id,
    required this.title,
    required this.source,
    required this.type,
    required this.paragraphs,
    required this.colorValue,
  });
}
