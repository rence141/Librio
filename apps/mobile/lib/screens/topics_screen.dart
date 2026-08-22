import 'package:flutter/material.dart';
import '../data/content_packs.dart';

/// Topics screen - displays topics for a subject
class TopicsScreen extends StatefulWidget {
  final String subject;
  
  const TopicsScreen({
    super.key,
    required this.subject,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  late List<ContentTopic> topics;
  
  @override
  void initState() {
    super.initState();
    _loadTopics();
  }
  
  void _loadTopics() {
    // Load topics from content packs
    final packs = ContentPacks.getAllPacks();
    final pack = packs.firstWhere(
      (p) => p.subject == widget.subject,
      orElse: () => ContentPacks.mathematicsPack,
    );
    
    setState(() {
      topics = pack.topics;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
          return _buildTopicCard(context, topic);
        },
      ),
    );
  }
  
  Widget _buildTopicCard(BuildContext context, ContentTopic topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.deepPurple[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${topic.problems.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
        title: Text(topic.name),
        subtitle: Text('${topic.problems.length} problems'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProblemsScreen(
                topic: topic,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Problems screen - displays problems for a topic
class ProblemsScreen extends StatefulWidget {
  final ContentTopic topic;
  
  const ProblemsScreen({
    super.key,
    required this.topic,
  });

  @override
  State<ProblemsScreen> createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
  int _currentProblemIndex = 0;
  late PracticeProblem _currentProblem;
  int? _selectedAnswerIndex;
  bool _showExplanation = false;
  
  @override
  void initState() {
    super.initState();
    _currentProblem = widget.topic.problems[_currentProblemIndex];
  }
  
  void _checkAnswer() {
    setState(() => _showExplanation = true);
  }
  
  void _nextProblem() {
    if (_currentProblemIndex < widget.topic.problems.length - 1) {
      setState(() {
        _currentProblemIndex++;
        _currentProblem = widget.topic.problems[_currentProblemIndex];
        _selectedAnswerIndex = null;
        _showExplanation = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have completed all problems!')),
      );
    }
  }
  
  void _previousProblem() {
    if (_currentProblemIndex > 0) {
      setState(() {
        _currentProblemIndex--;
        _currentProblem = widget.topic.problems[_currentProblemIndex];
        _selectedAnswerIndex = null;
        _showExplanation = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isCorrect = _selectedAnswerIndex == _currentProblem.correctAnswerIndex;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.name),
        subtitle: Text('Problem ${_currentProblemIndex + 1}/${widget.topic.problems.length}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentProblemIndex + 1) / widget.topic.problems.length,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 24),
            
            // Question
            Text(
              _currentProblem.question,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            // Options
            ..._buildOptions(),
            
            const SizedBox(height: 24),
            
            // Check button
            if (!_showExplanation)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAnswerIndex != null ? _checkAnswer : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Check Answer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            
            // Explanation
            if (_showExplanation) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green[50] : Colors.red[50],
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Correct!' : 'Incorrect',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentProblem.explanation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _currentProblemIndex > 0 ? _previousProblem : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _nextProblem,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildOptions() {
    return List.generate(
      _currentProblem.options.length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: _showExplanation ? null : () {
            setState(() => _selectedAnswerIndex = index);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedAnswerIndex == index
                    ? Colors.deepPurple
                    : Colors.grey[300]!,
                width: _selectedAnswerIndex == index ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _selectedAnswerIndex == index
                  ? Colors.deepPurple[50]
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedAnswerIndex == index
                          ? Colors.deepPurple
                          : Colors.grey[300]!,
                    ),
                    color: _selectedAnswerIndex == index
                        ? Colors.deepPurple
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedAnswerIndex == index
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentProblem.options[index],
                    style: Theme.of(context).textTheme.bodyMedium,
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
