import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/database_service.dart';
import '../utils/debug_logger.dart';

class FlashcardReviewScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const FlashcardReviewScreen({super.key, required this.databaseService});

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> {
  List<Flashcard> _cards = [];
  List<String> _decks = [];
  String? _selectedDeck;
  bool _isLoading = true;
  bool _isReviewing = false;
  int _currentIndex = 0;
  int _correct = 0;
  int _total = 0;

  // Colors
  static const Color _deepPurple = Color(0xFF7B2CBF);
  static const Color _cyan = Color(0xFF06B6D4);

  // Review state
  String? _selectedOption;
  bool? _answeredCorrectly;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _decks = await widget.databaseService.getFlashcardDecks();
      _cards = await widget.databaseService.getFlashcards(deck: _selectedDeck);
      setState(() => _isLoading = false);
    } catch (e, st) {
      DebugLogger.error('FlashcardReview', 'Failed to load data', e, st);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDeck(String? deck) async {
    setState(() {
      _selectedDeck = deck;
      _isLoading = true;
    });
    _cards = await widget.databaseService.getFlashcards(deck: deck);
    setState(() => _isLoading = false);
  }

  void _startReview() {
    if (_cards.isEmpty) return;
    setState(() {
      _isReviewing = true;
      _currentIndex = 0;
      _correct = 0;
      _total = _cards.length;
      _selectedOption = null;
      _answeredCorrectly = null;
      _textController.clear();
    });
  }

  void _answerMultipleChoice(int index) {
    if (_answeredCorrectly != null) return;
    final card = _cards[_currentIndex];
    final isCorrect = index == card.correctOptionIndex;
    setState(() {
      _selectedOption = card.options[index];
      _answeredCorrectly = isCorrect;
      if (isCorrect) _correct++;
    });
    widget.databaseService.updateFlashcardReview(card.id, isCorrect);
  }

  void _answerText() {
    if (_answeredCorrectly != null) return;
    final card = _cards[_currentIndex];
    final userAnswer = _textController.text.trim().toLowerCase();
    final correctAnswer = card.answer.trim().toLowerCase();
    final isCorrect = userAnswer.isNotEmpty &&
        (userAnswer == correctAnswer ||
            correctAnswer.contains(userAnswer) ||
            userAnswer.contains(correctAnswer));
    setState(() {
      _answeredCorrectly = isCorrect;
      if (isCorrect) _correct++;
    });
    widget.databaseService.updateFlashcardReview(card.id, isCorrect);
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answeredCorrectly = null;
        _textController.clear();
      });
    } else {
      // Review complete
      setState(() => _isReviewing = false);
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Review Complete!',
            style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _correct >= _total * 0.7 ? Icons.celebration : Icons.school,
              size: 64,
              color: _correct >= _total * 0.7 ? Colors.green : _deepPurple,
            ),
            const SizedBox(height: 16),
            Text(
              '$_correct / $_total correct',
              style: const TextStyle(
                  fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_correct / _total * 100).round()}% accuracy',
              style: TextStyle(
                  fontFamily: 'Fredoka', fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isReviewing = false);
            },
            child: const Text('Done',
                style: TextStyle(fontFamily: 'Fredoka')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startReview();
            },
            child: const Text('Review Again',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_deepPurple, Color(0xFF4F46E5), Color(0xFF3B82F6), _cyan],
              stops: [0.0, 0.33, 0.66, 1.0],
            ),
          ),
        ),
        title: const Text(
          'Flashcard Review',
          style: TextStyle(
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _deepPurple))
          : _isReviewing
              ? _buildReviewView()
              : _buildDeckSelectionView(),
    );
  }

  Widget _buildDeckSelectionView() {
    if (_cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.style, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'No Flashcards Yet',
                style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add flashcards from your study materials to start reviewing.',
                style: TextStyle(
                    fontFamily: 'Fredoka', color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Deck filter
        if (_decks.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButton<String>(
              value: _selectedDeck,
              hint: const Text('All Decks',
                  style: TextStyle(fontFamily: 'Fredoka')),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Decks')),
                ..._decks.map((d) => DropdownMenuItem(value: d, child: Text(d))),
              ],
              onChanged: _selectDeck,
            ),
          ),
        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatCard('Total', _cards.length.toString(), Icons.library_books),
              const SizedBox(width: 12),
              _buildStatCard('Decks', _decks.length.toString(), Icons.folder),
            ],
          ),
        ),
        // Card list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cards.length,
            itemBuilder: (context, index) => _buildCardPreview(_cards[index]),
          ),
        ),
        // Start review button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Review',
                  style: TextStyle(
                      fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: _deepPurple, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Fredoka', fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview(Flashcard card) {
    IconData typeIcon;
    String typeLabel;
    switch (card.type) {
      case FlashcardType.multipleChoice:
        typeIcon = Icons.list_alt;
        typeLabel = 'Multiple Choice';
        break;
      case FlashcardType.enumeration:
        typeIcon = Icons.format_list_numbered;
        typeLabel = 'Enumeration';
        break;
      case FlashcardType.identification:
        typeIcon = Icons.help_outline;
        typeLabel = 'Identification';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(typeIcon, color: _deepPurple),
        title: Text(card.question,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600)),
        subtitle: Text('$typeLabel • ${card.deck}',
            style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: Colors.grey[600])),
        trailing: Text('${card.correctCount}/${card.reviewCount}',
            style: TextStyle(fontFamily: 'Fredoka', color: Colors.grey[500], fontSize: 12)),
      ),
    );
  }

  Widget _buildReviewView() {
    final card = _cards[_currentIndex];
    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _total,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(_deepPurple),
        ),
        // Progress text
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Card ${_currentIndex + 1} of $_total',
                  style: TextStyle(fontFamily: 'Fredoka', color: Colors.grey[600])),
              Text('Score: $_correct',
                  style: const TextStyle(
                      fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: _deepPurple)),
            ],
          ),
        ),
        // Card content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_deepPurple, _cyan]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    card.type.name.toUpperCase(),
                    style: const TextStyle(
                        fontFamily: 'Fredoka',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                // Question
                const Text('Question',
                    style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  card.question,
                  style: const TextStyle(
                      fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                // Answer area based on type
                if (card.type == FlashcardType.multipleChoice)
                  _buildMultipleChoiceOptions(card)
                else
                  _buildTextAnswer(card),
                // Show answer after answering
                if (_answeredCorrectly != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _answeredCorrectly!
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _answeredCorrectly! ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _answeredCorrectly! ? Icons.check_circle : Icons.cancel,
                              color: _answeredCorrectly! ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _answeredCorrectly! ? 'Correct!' : 'Incorrect',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _answeredCorrectly! ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Correct Answer:',
                            style: TextStyle(fontFamily: 'Fredoka', color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          card.answer,
                          style: const TextStyle(
                              fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Next button
        if (_answeredCorrectly != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex < _cards.length - 1 ? 'Next Card' : 'Finish',
                  style: const TextStyle(
                      fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMultipleChoiceOptions(Flashcard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: card.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedOption == option;
        Color? bgColor;
        Color? borderColor;
        if (_answeredCorrectly != null) {
          if (index == card.correctOptionIndex) {
            bgColor = Colors.green[50];
            borderColor = Colors.green;
          } else if (isSelected) {
            bgColor = Colors.red[50];
            borderColor = Colors.red;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: _answeredCorrectly == null ? () => _answerMultipleChoice(index) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor ?? Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor ?? Colors.grey[300]!,
                  width: isSelected || (index == card.correctOptionIndex && _answeredCorrectly != null) ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor ?? Colors.grey[400]!),
                      color: isSelected ? (borderColor ?? Colors.grey) : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(option,
                        style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAnswer(Flashcard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Answer',
            style: TextStyle(fontFamily: 'Fredoka', color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          enabled: _answeredCorrectly == null,
          maxLines: card.type == FlashcardType.enumeration ? 3 : 1,
          decoration: InputDecoration(
            hintText: card.type == FlashcardType.enumeration
                ? 'List your answers (one per line)'
                : 'Type your answer...',
            hintStyle: const TextStyle(fontFamily: 'Fredoka'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _deepPurple, width: 2),
            ),
          ),
          style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_answeredCorrectly == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _answerText,
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Answer',
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
