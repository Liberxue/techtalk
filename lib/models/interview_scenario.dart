class InterviewScenario {
  final String name;
  final String description;
  final List<InterviewTurn> turns;

  const InterviewScenario({
    required this.name,
    required this.description,
    required this.turns,
  });
}

class InterviewTurn {
  final String question;
  final List<String> keyPhrases;
  final String idealAnswer;
  final List<GrammarFix> commonFixes;

  const InterviewTurn({
    required this.question,
    required this.keyPhrases,
    required this.idealAnswer,
    this.commonFixes = const [],
  });
}

class GrammarFix {
  final String wrong;
  final String correct;

  const GrammarFix({required this.wrong, required this.correct});
}

const interviewScenarios = [
  InterviewScenario(
    name: 'System Design',
    description: 'design a distributed system',
    turns: [
      InterviewTurn(
        question:
            'Let\'s design a URL shortening service like bit.ly. Can you walk me through your high-level approach?',
        keyPhrases: [
          'hash',
          'database',
          'unique',
          'redirect',
          'encode',
          'base62',
          'collision',
          'short code',
        ],
        idealAnswer:
            'We can use a hash function or base62 encoding to generate unique short codes, store the mapping in a database, and redirect users by looking up the original URL.',
        commonFixes: [
          GrammarFix(wrong: 'it has problem', correct: 'there is an issue'),
          GrammarFix(wrong: 'make short', correct: 'shorten'),
          GrammarFix(wrong: 'save to database', correct: 'persist in the database'),
        ],
      ),
      InterviewTurn(
        question:
            'How would you handle the case where two different URLs generate the same short code?',
        keyPhrases: [
          'collision',
          'retry',
          'unique constraint',
          'append',
          'counter',
          'check',
        ],
        idealAnswer:
            'We can handle collisions by checking uniqueness before insertion, retrying with a modified input, or using a counter-based approach to guarantee uniqueness.',
        commonFixes: [
          GrammarFix(wrong: 'same same', correct: 'identical'),
          GrammarFix(wrong: 'do again', correct: 'retry the operation'),
        ],
      ),
      InterviewTurn(
        question:
            'What database would you choose and why? How would you scale the read path?',
        keyPhrases: [
          'cache',
          'redis',
          'nosql',
          'partition',
          'shard',
          'replica',
          'read replica',
          'CDN',
        ],
        idealAnswer:
            'I would use a NoSQL store like DynamoDB for fast key-value lookups, add a Redis cache layer for hot URLs, and use read replicas or partitioning to scale horizontally.',
        commonFixes: [
          GrammarFix(wrong: 'more fast', correct: 'faster'),
          GrammarFix(wrong: 'put cache', correct: 'add a caching layer'),
        ],
      ),
      InterviewTurn(
        question:
            'How would you design the analytics feature to track click counts per URL?',
        keyPhrases: [
          'counter',
          'event',
          'stream',
          'kafka',
          'async',
          'batch',
          'aggregate',
          'time series',
        ],
        idealAnswer:
            'I would use an event streaming system like Kafka to process click events asynchronously, aggregate them in batches, and store time-series data for analytics queries.',
        commonFixes: [
          GrammarFix(wrong: 'count click', correct: 'track click metrics'),
          GrammarFix(wrong: 'real time process', correct: 'process in real-time'),
        ],
      ),
    ],
  ),
  InterviewScenario(
    name: 'Behavioral',
    description: 'past experience & leadership',
    turns: [
      InterviewTurn(
        question:
            'Tell me about a time when you had to make a difficult technical decision with incomplete information.',
        keyPhrases: [
          'trade-off',
          'risk',
          'decision',
          'stakeholder',
          'data',
          'outcome',
          'learned',
        ],
        idealAnswer:
            'In a past project, I had to choose between two database architectures without full performance benchmarks. I gathered what data I could, consulted with the team, made a reversible decision, and set up metrics to validate it.',
        commonFixes: [
          GrammarFix(wrong: 'I was decide', correct: 'I decided'),
          GrammarFix(wrong: 'not have enough', correct: 'lacked sufficient'),
        ],
      ),
      InterviewTurn(
        question:
            'Describe a situation where you disagreed with a teammate. How did you handle it?',
        keyPhrases: [
          'disagree',
          'perspective',
          'compromise',
          'listen',
          'resolve',
          'respect',
          'outcome',
        ],
        idealAnswer:
            'I listened to their perspective, shared my reasoning with data, and we found a compromise that incorporated the best of both approaches.',
        commonFixes: [
          GrammarFix(wrong: 'he was wrong', correct: 'we had different perspectives'),
          GrammarFix(wrong: 'I tell him', correct: 'I explained my reasoning'),
        ],
      ),
      InterviewTurn(
        question:
            'How do you prioritize tasks when everything seems urgent?',
        keyPhrases: [
          'impact',
          'urgency',
          'matrix',
          'stakeholder',
          'delegate',
          'communicate',
          'deadline',
        ],
        idealAnswer:
            'I use an impact-urgency matrix, communicate with stakeholders to clarify true deadlines, and delegate where possible to ensure the highest-impact work gets done first.',
        commonFixes: [
          GrammarFix(wrong: 'everything important', correct: 'everything seems critical'),
          GrammarFix(wrong: 'do all together', correct: 'handle them simultaneously'),
        ],
      ),
    ],
  ),
  InterviewScenario(
    name: 'API Design',
    description: 'design RESTful or gRPC APIs',
    turns: [
      InterviewTurn(
        question:
            'Design a REST API for a task management system. What endpoints would you create?',
        keyPhrases: [
          'CRUD',
          'REST',
          'endpoint',
          'resource',
          'GET',
          'POST',
          'PUT',
          'DELETE',
          'status code',
        ],
        idealAnswer:
            'I would create RESTful endpoints like GET /tasks, POST /tasks, PUT /tasks/:id, DELETE /tasks/:id, with proper status codes and pagination support.',
        commonFixes: [
          GrammarFix(wrong: 'make API', correct: 'design the API'),
          GrammarFix(wrong: 'return back', correct: 'return'),
        ],
      ),
      InterviewTurn(
        question:
            'How would you handle authentication and rate limiting for this API?',
        keyPhrases: [
          'JWT',
          'OAuth',
          'token',
          'rate limit',
          'throttle',
          'middleware',
          'header',
          '401',
          '429',
        ],
        idealAnswer:
            'I would use JWT tokens for authentication, implement rate limiting middleware with a sliding window algorithm, and return proper 401 and 429 status codes.',
        commonFixes: [
          GrammarFix(wrong: 'check user login', correct: 'authenticate the user'),
          GrammarFix(wrong: 'too many request', correct: 'too many requests'),
        ],
      ),
      InterviewTurn(
        question:
            'How would you version this API and handle backward compatibility?',
        keyPhrases: [
          'version',
          'v1',
          'v2',
          'backward compatible',
          'deprecate',
          'header',
          'URL path',
          'migration',
        ],
        idealAnswer:
            'I would use URL path versioning like /v1/tasks, maintain backward compatibility by adding new fields as optional, and provide deprecation notices with migration guides.',
        commonFixes: [
          GrammarFix(wrong: 'old version break', correct: 'the old version would break'),
          GrammarFix(wrong: 'change API', correct: 'evolve the API'),
        ],
      ),
    ],
  ),
];
