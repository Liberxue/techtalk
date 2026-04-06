/// Represents a playable content item (book chapter, news article).
class AudioContent {
  final String id;
  final String title;
  final String source; // book name or news source
  final String type; // 'book' | 'news'
  final List<String> paragraphs;
  final String? imageUrl;
  final Duration? estimatedDuration;

  const AudioContent({
    required this.id,
    required this.title,
    required this.source,
    required this.type,
    required this.paragraphs,
    this.imageUrl,
    this.estimatedDuration,
  });

  String get fullText => paragraphs.join('\n\n');

  /// Estimated reading time at ~150 words per minute
  Duration get duration {
    if (estimatedDuration != null) return estimatedDuration!;
    final wordCount = fullText.split(RegExp(r'\s+')).length;
    return Duration(seconds: (wordCount / 2.5).round()); // TTS is ~150wpm
  }

  String get durationLabel {
    final mins = duration.inMinutes;
    if (mins < 1) return '<1 min';
    return '$mins min';
  }
}

/// Sample content for demo
const sampleContent = [
  AudioContent(
    id: 'rust-ownership',
    title: 'Understanding Ownership',
    source: 'The Rust Programming Language',
    type: 'book',
    paragraphs: [
      'Ownership is Rust\'s most unique feature and has deep implications for the rest of the language. It enables Rust to make memory safety guarantees without needing a garbage collector, so it\'s important to understand how ownership works.',
      'All programs have to manage the way they use a computer\'s memory while running. Some languages have garbage collection that regularly looks for no longer used memory as the program runs. In other languages, the programmer must explicitly allocate and free the memory.',
      'Rust uses a third approach. Memory is managed through a system of ownership with a set of rules that the compiler checks. If any of the rules are violated, the program won\'t compile. None of the features of ownership will slow down your program while it\'s running.',
      'The Stack and the Heap. In many programming languages, you don\'t have to think about the stack and the heap very often. But in a systems programming language like Rust, whether a value is on the stack or the heap affects how the language behaves and why you have to make certain decisions.',
    ],
  ),
  AudioContent(
    id: 'rust-borrowing',
    title: 'References and Borrowing',
    source: 'The Rust Programming Language',
    type: 'book',
    paragraphs: [
      'The issue with the tuple code is that we have to return the String to the calling function so we can still use the String after the call, because the String was moved into the function.',
      'Instead, we can provide a reference to the String value. A reference is like a pointer in that it\'s an address we can follow to access the data stored at that address. That data is owned by some other variable.',
      'Unlike a pointer, a reference is guaranteed to point to a valid value of a particular type for the life of that reference. We call the action of creating a reference borrowing.',
      'Just as variables are immutable by default, so are references. We\'re not allowed to modify something we have a reference to. But mutable references have one big restriction, you can have only one mutable reference to a particular piece of data at a time.',
    ],
  ),
  AudioContent(
    id: 'news-webassembly',
    title: 'WebAssembly 2.0 Brings Garbage Collection to the Browser',
    source: 'TechCrunch',
    type: 'news',
    paragraphs: [
      'The WebAssembly community group has officially released the garbage collection proposal, enabling languages like Java, Kotlin, and Dart to compile efficiently to WebAssembly without shipping their own garbage collector.',
      'This is a significant milestone for the web platform. Previously, languages with managed memory had to include a full garbage collector in their WebAssembly output, resulting in large binary sizes and reduced performance.',
      'With native garbage collection support, these languages can now rely on the browser\'s built-in GC, reducing binary sizes by up to sixty percent and improving startup times dramatically.',
      'Major browser vendors including Chrome, Firefox, and Safari have already shipped implementations. The feature is expected to accelerate the adoption of WebAssembly for production web applications.',
    ],
  ),
  AudioContent(
    id: 'news-ai-compiler',
    title: 'How AI Is Transforming Compiler Optimization',
    source: 'IEEE Spectrum',
    type: 'news',
    paragraphs: [
      'Researchers at Google and MIT have demonstrated that machine learning models can discover compiler optimizations that outperform hand-tuned heuristics developed over decades.',
      'The new system, called AutoPhase, uses reinforcement learning to explore the vast space of possible optimization sequences. In benchmarks, it found optimization orders that produced code running up to fifteen percent faster than the best known sequences.',
      'Traditional compilers apply optimizations in a fixed order determined by compiler engineers. But the interaction between different optimization passes is complex and depends heavily on the specific code being compiled.',
      'This work suggests that AI-driven compilers could automatically adapt their optimization strategy to each individual program, potentially unlocking performance gains across the entire software ecosystem.',
    ],
  ),
  AudioContent(
    id: 'news-edge-computing',
    title: 'The Rise of Edge Computing in Real-Time Applications',
    source: 'Hacker News',
    type: 'news',
    paragraphs: [
      'Edge computing is moving from buzzword to production reality. Companies like Cloudflare, Fastly, and Deno are deploying compute infrastructure closer to end users, reducing latency from hundreds of milliseconds to single digits.',
      'The key insight is that not all computation needs to happen in a centralized data center. For real-time applications like gaming, video conferencing, and IoT, processing data at the edge dramatically improves user experience.',
      'New frameworks are emerging that blur the line between client and server. Functions can be deployed globally and executed at the nearest edge location, with automatic data replication and consistency guarantees.',
      'The challenge remains in debugging and observability. When your code runs in two hundred locations simultaneously, traditional logging and monitoring approaches break down. The industry is still developing tools for this new paradigm.',
    ],
  ),
];
