import 'package:flutter_test/flutter_test.dart';
import 'package:librio/services/content_manager.dart';

void main() {
  group('ContentManager', () {
    late ContentManager manager;
    late SubjectPack testPack;

    setUp(() {
      manager = ContentManager();
      manager.initialize();

      // Create test pack
      testPack = SubjectPack(
        id: 'test_pack',
        title: 'Test Pack',
        subject: 'Mathematics',
        description: 'Test subject pack',
        topics: [
          ContentTopic(
            id: 'test_topic_1',
            title: 'Test Topic 1',
            description: 'Test topic description',
            subject: 'Mathematics',
            difficulty: 1,
            concepts: ['concept1', 'concept2'],
            keywords: ['keyword1', 'keyword2'],
            createdAt: DateTime.now(),
          ),
        ],
        problems: [
          PracticeProblem(
            id: 'test_problem_1',
            topicId: 'test_topic_1',
            question: 'Test question?',
            options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
            correctAnswerIndex: 0,
            explanation: 'Test explanation',
            difficulty: 1,
            createdAt: DateTime.now(),
          ),
        ],
        totalTopics: 1,
        totalProblems: 1,
        createdAt: DateTime.now(),
      );
    });

    test('initializes successfully', () {
      expect(() => manager.initialize(), returnsNormally);
    });

    test('adds subject pack', () {
      manager.addSubjectPack(testPack);
      expect(manager.getSubjectPack('test_pack'), isNotNull);
    });

    test('gets subject pack by id', () {
      manager.addSubjectPack(testPack);
      final pack = manager.getSubjectPack('test_pack');
      expect(pack?.title, 'Test Pack');
    });

    test('gets all subject packs', () {
      manager.addSubjectPack(testPack);
      final packs = manager.getAllSubjectPacks();
      expect(packs.length, greaterThan(0));
    });

    test('gets subject packs by subject', () {
      manager.addSubjectPack(testPack);
      final packs = manager.getSubjectPacksBySubject('Mathematics');
      expect(packs.isNotEmpty, true);
    });

    test('gets topic by id', () {
      manager.addSubjectPack(testPack);
      final topic = manager.getTopic('test_topic_1');
      expect(topic?.title, 'Test Topic 1');
    });

    test('gets topics by subject', () {
      manager.addSubjectPack(testPack);
      final topics = manager.getTopicsBySubject('Mathematics');
      expect(topics.isNotEmpty, true);
    });

    test('gets problem by id', () {
      manager.addSubjectPack(testPack);
      final problem = manager.getProblem('test_problem_1');
      expect(problem?.question, 'Test question?');
    });

    test('gets problems by topic', () {
      manager.addSubjectPack(testPack);
      final problems = manager.getProblemsByTopic('test_topic_1');
      expect(problems.isNotEmpty, true);
    });

    test('gets problems by difficulty', () {
      manager.addSubjectPack(testPack);
      final problems = manager.getProblemsByDifficulty(1);
      expect(problems.isNotEmpty, true);
    });

    test('gets statistics', () {
      manager.addSubjectPack(testPack);
      final stats = manager.getStatistics();
      expect(stats['totalPacks'], greaterThan(0));
      expect(stats['totalTopics'], greaterThan(0));
      expect(stats['totalProblems'], greaterThan(0));
    });

    test('searches topics', () {
      manager.addSubjectPack(testPack);
      final results = manager.searchTopics('Test');
      expect(results.isNotEmpty, true);
    });

    test('gets featured content', () {
      manager.addSubjectPack(testPack);
      final featured = manager.getFeaturedContent(5);
      expect(featured, isNotEmpty);
    });

    test('clears content', () {
      manager.addSubjectPack(testPack);
      manager.clearContent();
      expect(manager.getAllSubjectPacks().length, 0);
    });

    test('content topic converts to JSON', () {
      final topic = testPack.topics.first;
      final json = topic.toJson();
      expect(json['id'], 'test_topic_1');
      expect(json['title'], 'Test Topic 1');
    });

    test('practice problem converts to JSON', () {
      final problem = testPack.problems.first;
      final json = problem.toJson();
      expect(json['id'], 'test_problem_1');
      expect(json['question'], 'Test question?');
    });

    test('subject pack converts to JSON', () {
      final json = testPack.toJson();
      expect(json['id'], 'test_pack');
      expect(json['title'], 'Test Pack');
      expect(json['topics'], isNotEmpty);
      expect(json['problems'], isNotEmpty);
    });
  });
}
