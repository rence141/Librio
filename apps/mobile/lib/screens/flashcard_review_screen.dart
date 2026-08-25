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

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen>
    with TickerProviderStateMixin {
  List<Flashcard> _cards = [];
  List<String> _decks = [];
  String? _selectedDeck;
  Set<String> _selectedDecksForGroup = {};
  bool _isGroupReviewMode = false;
  bool _isLoading = true;
  bool _isReviewing = false;
  int _currentIndex = 0;
  int _correct = 0;
  int _total = 0;
  bool _showAnswer = false;

  // Spaced repetition stats
  final Map<String, int> _streaks = {};
  int _sessionBest = 0;

  // Colors
  static const Color _deepPurple = Color(0xFF7B2CBF);
  static const Color _cyan = Color(0xFF06B6D4);

  // Theme helpers
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _textColor => _isDark ? Colors.white : Colors.black87;
  Color get _subTextColor => _isDark ? Colors.white70 : Colors.black54;
  Color get _cardBg => _isDark ? const Color(0xFF1F1F2E) : Colors.white;
  Color get _divider => _isDark ? Colors.grey[700]! : Colors.grey[200]!;

  // Review state
  String? _selectedOption;
  bool? _answeredCorrectly;
  final TextEditingController _textController = TextEditingController();

  // Card flip animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _frontSide = true;

  // Slide transition animation between cards
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutQuad),
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _loadData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _decks = await widget.databaseService.getFlashcardDecks();
      _cards = await widget.databaseService.getFlashcards(deck: _selectedDeck);
      if (mounted) setState(() => _isLoading = false);
    } catch (e, st) {
      DebugLogger.error('FlashcardReview', 'Failed to load data', e, st);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDeck(String? deck) async {
    setState(() {
      _selectedDeck = deck;
      _isLoading = true;
    });
    _cards = await widget.databaseService.getFlashcards(deck: deck);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadGroupReviewCards() async {
    if (_selectedDecksForGroup.isEmpty) {
      setState(() => _cards = []);
      return;
    }
    try {
      final allCards = <Flashcard>[];
      for (final deck in _selectedDecksForGroup) {
        final cards = await widget.databaseService.getFlashcards(deck: deck);
        allCards.addAll(cards);
      }
      setState(() => _cards = allCards);
    } catch (e, st) {
      DebugLogger.error('FlashcardReview', 'Failed to load group cards', e, st);
    }
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
      _showAnswer = false;
      _frontSide = true;
      _streaks.clear();
      _sessionBest = 0;
    });
    _slideController.forward(from: 0);
  }

  void _answerMultipleChoice(int index) {
    if (_answeredCorrectly != null) return;
    final card = _cards[_currentIndex];
    final isCorrect = index == card.correctOptionIndex;
    setState(() {
      _selectedOption = card.options[index];
      _answeredCorrectly = isCorrect;
      if (isCorrect) {
        _correct++;
        _streaks[card.id] = (_streaks[card.id] ?? 0) + 1;
        if (_streaks[card.id]! > _sessionBest) _sessionBest = _streaks[card.id]!;
      } else {
        _streaks[card.id] = 0;
      }
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
      if (isCorrect) {
        _correct++;
        _streaks[card.id] = (_streaks[card.id] ?? 0) + 1;
        if (_streaks[card.id]! > _sessionBest) _sessionBest = _streaks[card.id]!;
      } else {
        _streaks[card.id] = 0;
      }
    });
    widget.databaseService.updateFlashcardReview(card.id, isCorrect);
  }

  void _flipCard() {
    if (_frontSide) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    _frontSide = !_frontSide;
    setState(() => _showAnswer = !_showAnswer);
  }

  void _nextCard() {
    if (_currentIndex >= _cards.length - 1) {
      setState(() => _isReviewing = false);
      _showResults();
    } else {
      _slideController.reset();
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answeredCorrectly = null;
        _textController.clear();
        _showAnswer = false;
        _frontSide = true;
      });
      _flipController.reset();
      _slideController.forward();
    }
  }

  void _previousCard() {
    if (_currentIndex <= 0) return;
    _slideController.reset();
    setState(() {
      _currentIndex--;
      _selectedOption = null;
      _answeredCorrectly = null;
      _textController.clear();
      _showAnswer = false;
      _frontSide = true;
    });
    _flipController.reset();
    _slideController.forward();
  }

  void _showResults() {
    final accuracy = (_correct / _total * 100).round();
    final isGreat = accuracy >= 70;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1F1F2E) : Colors.white,
        title: Text('Review Complete!',
            style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
                color: _textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isGreat
                      ? [Colors.green, Colors.teal]
                      : [_deepPurple, _cyan],
                ),
              ),
              child: Icon(
                isGreat ? Icons.celebration : Icons.school,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$_correct / $_total correct',
              style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textColor),
            ),
            const SizedBox(height: 8),
            Text(
              '$accuracy% accuracy',
              style: TextStyle(
                  fontFamily: 'Fredoka', fontSize: 16, color: _subTextColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Best streak: $_sessionBest',
                    style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: _textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done', style: TextStyle(fontFamily: 'Fredoka', color: _subTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startReview();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _deepPurple,
              foregroundColor: Colors.white,
            ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDark ? Colors.grey[800] : Colors.grey[100],
                ),
                child: Icon(Icons.style, size: 50, color: _deepPurple.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 16),
              Text(
                'No Flashcards Yet',
                style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Create flashcards to start studying.',
                style: TextStyle(
                    fontFamily: 'Fredoka', color: _subTextColor, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateFlashcardDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Manually',
                      style: TextStyle(fontFamily: 'Fredoka', fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'generate'),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate from Chat',
                      style: TextStyle(fontFamily: 'Fredoka', fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _deepPurple,
                    side: const BorderSide(color: _deepPurple, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // New flashcard button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateFlashcardDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Flashcard',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        // Deck filter / Group review toggle
        if (_decks.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _isGroupReviewMode ? null : _selectedDeck,
                    hint: Text('All Decks',
                        style: TextStyle(fontFamily: 'Fredoka', color: _textColor)),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: null, child: Text('All Decks', style: TextStyle(color: _textColor))),
                      ..._decks.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(color: _textColor)))),
                    ],
                    onChanged: _isGroupReviewMode
                        ? null
                        : (value) {
                            _selectedDecksForGroup.clear();
                            _selectDeck(value);
                          },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isGroupReviewMode = !_isGroupReviewMode;
                      if (!_isGroupReviewMode) {
                        _selectedDecksForGroup.clear();
                      }
                    });
                  },
                  icon: Icon(_isGroupReviewMode ? Icons.check : Icons.layers),
                  label: Text(_isGroupReviewMode ? 'Group' : 'Single',
                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isGroupReviewMode ? _deepPurple : Colors.grey[300],
                    foregroundColor: _isGroupReviewMode ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        // Group review deck selector
        if (_isGroupReviewMode && _decks.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: _decks.map((deck) {
                final isSelected = _selectedDecksForGroup.contains(deck);
                return FilterChip(
                  label: Text(deck, style: const TextStyle(fontFamily: 'Fredoka')),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDecksForGroup.add(deck);
                      } else {
                        _selectedDecksForGroup.remove(deck);
                      }
                      _loadGroupReviewCards();
                    });
                  },
                  backgroundColor: _isDark ? Colors.grey[800] : Colors.grey[200],
                  selectedColor: _deepPurple.withValues(alpha: 0.3),
                  side: BorderSide(
                    color: isSelected ? _deepPurple : _divider,
                  ),
                );
              }).toList(),
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
              onPressed: _cards.isEmpty ? null : _startReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cards.isEmpty ? Colors.grey[300] : _deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isGroupReviewMode && _selectedDecksForGroup.isNotEmpty
                    ? 'Start Group Review'
                    : 'Start Review',
                style: const TextStyle(
                    fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: _deepPurple, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textColor)),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Fredoka', fontSize: 12, color: _subTextColor)),
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

    final accuracy = card.reviewCount > 0
        ? (card.correctCount / card.reviewCount * 100).round()
        : null;

    return Card(
      color: _cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(typeIcon, color: _deepPurple),
        title: Text(card.question,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: _textColor)),
        subtitle: Row(
          children: [
            Text('$typeLabel • ${card.deck}',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: _subTextColor)),
            if (accuracy != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accuracy >= 70 ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$accuracy%',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accuracy >= 70 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditFlashcardDialog(card);
            } else if (value == 'delete') {
              _showDeleteConfirmation(card);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(fontFamily: 'Fredoka', color: _textColor)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(fontFamily: 'Fredoka', color: _textColor)),
                ],
              ),
            ),
          ],
          position: PopupMenuPosition.under,
          icon: Icon(Icons.more_vert, size: 20, color: _subTextColor),
        ),
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
          backgroundColor: _divider,
          valueColor: const AlwaysStoppedAnimation<Color>(_deepPurple),
        ),
        // Progress text + streak
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Card ${_currentIndex + 1} of $_total',
                  style: TextStyle(fontFamily: 'Fredoka', color: _subTextColor)),
              Row(
                children: [
                  if (_sessionBest > 0) ...[
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text('$_sessionBest',
                        style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                    const SizedBox(width: 12),
                  ],
                  Text('Score: $_correct',
                      style: const TextStyle(
                          fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: _deepPurple)),
                ],
              ),
            ],
          ),
        ),
        // Card content with slide animation
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300 && _answeredCorrectly != null) {
                  _nextCard();
                } else if (details.primaryVelocity! > 300) {
                  _previousCard();
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + flip hint
                    Row(
                      children: [
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
                        const Spacer(),
                        if (card.type == FlashcardType.identification ||
                            card.type == FlashcardType.enumeration)
                          TextButton.icon(
                            onPressed: _flipCard,
                            icon: Icon(Icons.flip, size: 18, color: _deepPurple),
                            label: Text(
                              _showAnswer ? 'Hide' : 'Reveal',
                              style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: _deepPurple),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Question
                    Text('Question',
                        style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            color: _subTextColor)),
                    const SizedBox(height: 8),
                    Text(
                      card.question,
                      style: TextStyle(
                          fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.w600, color: _textColor),
                    ),
                    const SizedBox(height: 24),
                    // Answer area based on type
                    if (card.type == FlashcardType.multipleChoice)
                      _buildMultipleChoiceOptions(card)
                    else
                      _buildTextAnswer(card),
                    // Show answer after answering or flip
                    if (_answeredCorrectly != null || _showAnswer) ...[
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _showAnswer ? _flipAnimation.value * 3.14159 : 0;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(angle.toDouble()),
                            child: child,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _answeredCorrectly == false
                                ? Colors.red.withValues(alpha: _isDark ? 0.15 : 0.08)
                                : _answeredCorrectly == true
                                    ? Colors.green.withValues(alpha: _isDark ? 0.15 : 0.08)
                                    : _isDark ? Colors.grey[800] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _answeredCorrectly == false
                                  ? Colors.red
                                  : _answeredCorrectly == true
                                      ? Colors.green
                                      : _divider,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_answeredCorrectly != null) ...[
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
                              ],
                              Text('Correct Answer:',
                                  style: TextStyle(fontFamily: 'Fredoka', color: _subTextColor)),
                              const SizedBox(height: 4),
                              Text(
                                card.answer,
                                style: TextStyle(
                                    fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.w600, color: _textColor),
                              ),
                              // Review stats
                              if (card.reviewCount > 0) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.history, size: 14, color: _subTextColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reviewed ${card.reviewCount}x • ${card.correctCount} correct',
                                      style: TextStyle(fontFamily: 'Fredoka', fontSize: 11, color: _subTextColor),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentIndex > 0)
                IconButton(
                  onPressed: _previousCard,
                  icon: Icon(Icons.arrow_back, color: _subTextColor),
                  tooltip: 'Previous',
                ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _answeredCorrectly != null
                      ? (_currentIndex >= _cards.length - 1
                          ? () {
                              setState(() => _isReviewing = false);
                              _showResults();
                            }
                          : _nextCard)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _isDark ? Colors.grey[700] : Colors.grey[300],
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
              if (_currentIndex < _cards.length - 1 && _answeredCorrectly != null)
                IconButton(
                  onPressed: _nextCard,
                  icon: Icon(Icons.arrow_forward, color: _deepPurple),
                  tooltip: 'Next',
                ),
            ],
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
            bgColor = Colors.green.withValues(alpha: _isDark ? 0.15 : 0.08);
            borderColor = Colors.green;
          } else if (isSelected) {
            bgColor = Colors.red.withValues(alpha: _isDark ? 0.15 : 0.08);
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
                color: bgColor ?? (_isDark ? Colors.grey[850] : Colors.grey[50]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor ?? _divider,
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
                      border: Border.all(color: borderColor ?? (_isDark ? Colors.grey[600]! : Colors.grey[400]!)),
                      color: isSelected ? (borderColor ?? Colors.grey) : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(option,
                        style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, color: _textColor)),
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
        Text('Your Answer',
            style: TextStyle(fontFamily: 'Fredoka', color: _subTextColor)),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          enabled: _answeredCorrectly == null,
          maxLines: card.type == FlashcardType.enumeration ? 3 : 1,
          decoration: InputDecoration(
            hintText: card.type == FlashcardType.enumeration
                ? 'List your answers (one per line)'
                : 'Type your answer...',
            hintStyle: TextStyle(fontFamily: 'Fredoka', color: _subTextColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _deepPurple, width: 2),
            ),
          ),
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, color: _textColor),
        ),
        const SizedBox(height: 12),
        if (_answeredCorrectly == null)
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _flipCard,
                icon: Icon(Icons.flip, size: 18, color: _deepPurple),
                label: Text('Reveal', style: TextStyle(fontFamily: 'Fredoka', color: _deepPurple)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  side: const BorderSide(color: _deepPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Show dialog to create a flashcard manually
  void _showCreateFlashcardDialog() {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final deckController = TextEditingController();
    String selectedType = 'identification';
    List<TextEditingController> choiceControllers = [];
    int correctChoiceIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : Colors.black87;
          final subTextColor = isDark ? Colors.white70 : Colors.black54;
          final fieldBg = isDark ? const Color(0xFF2A2A3E) : Colors.grey[100];
          final divider = isDark ? Colors.grey[700]! : Colors.grey[200]!;

          InputDecoration modernInput(String hint, {Widget? prefixIcon}) {
            return InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontFamily: 'Fredoka', color: subTextColor),
              filled: true,
              fillColor: fieldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _deepPurple, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: prefixIcon,
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A28) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header with gradient
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_deepPurple, _cyan]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_card, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Flashcard',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Add a new card to your deck',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 13,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            for (var c in choiceControllers) {
                              c.dispose();
                            }
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: divider, height: 1),
                  // Form content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Deck name with icon
                          Text('Deck',
                              style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: deckController,
                            decoration: modernInput('e.g., Biology 101',
                                prefixIcon: Icon(Icons.folder_outlined, size: 20, color: subTextColor)),
                            style: TextStyle(fontFamily: 'Fredoka', color: textColor),
                          ),
                          const SizedBox(height: 20),
                          // Type selector — modern cards
                          Text('Card Type',
                              style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeCard(
                                  icon: Icons.edit_note,
                                  label: 'Short Answer',
                                  subtitle: 'Type the answer',
                                  isSelected: selectedType == 'identification',
                                  isDark: isDark,
                                  onTap: () {
                                    setState(() {
                                      selectedType = 'identification';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTypeCard(
                                  icon: Icons.list_alt,
                                  label: 'Multiple Choice',
                                  subtitle: 'Pick from options',
                                  isSelected: selectedType == 'multiple_choice',
                                  isDark: isDark,
                                  onTap: () {
                                    setState(() {
                                      selectedType = 'multiple_choice';
                                      if (choiceControllers.isEmpty) {
                                        choiceControllers = List.generate(2, (_) => TextEditingController());
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Question
                          Text('Question',
                              style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: questionController,
                            decoration: modernInput('Enter the question...'),
                            style: TextStyle(fontFamily: 'Fredoka', color: textColor),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          // Answer section
                          if (selectedType == 'identification') ...[
                            Text('Answer',
                                style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: subTextColor)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: answerController,
                              decoration: modernInput('Enter the answer...'),
                              style: TextStyle(fontFamily: 'Fredoka', color: textColor),
                              maxLines: 3,
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Choices',
                                    style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: subTextColor)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _deepPurple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${choiceControllers.length}/5',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _deepPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Tap the circle to mark the correct answer',
                                style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 11,
                                    color: subTextColor)),
                            const SizedBox(height: 10),
                            Column(
                              children: List.generate(choiceControllers.length, (index) {
                                final isCorrect = index == correctChoiceIndex;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => correctChoiceIndex = index);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCorrect ? Colors.green : Colors.transparent,
                                            border: Border.all(
                                              color: isCorrect ? Colors.green : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                                              width: 2,
                                            ),
                                          ),
                                          child: isCorrect
                                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: choiceControllers[index],
                                          decoration: modernInput('Choice ${index + 1}'),
                                          style: TextStyle(fontFamily: 'Fredoka', color: textColor),
                                        ),
                                      ),
                                      if (choiceControllers.length > 2)
                                        IconButton(
                                          icon: Icon(Icons.close, size: 18, color: subTextColor),
                                          onPressed: () {
                                            setState(() {
                                              choiceControllers[index].dispose();
                                              choiceControllers.removeAt(index);
                                              if (correctChoiceIndex >= choiceControllers.length) {
                                                correctChoiceIndex = choiceControllers.length - 1;
                                              }
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            if (choiceControllers.length < 5)
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      choiceControllers.add(TextEditingController());
                                    });
                                  },
                                  icon: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _deepPurple.withValues(alpha: 0.15),
                                    ),
                                    child: const Icon(Icons.add, size: 16, color: _deepPurple),
                                  ),
                                  label: Text('Add Choice',
                                      style: TextStyle(fontFamily: 'Fredoka', color: _deepPurple, fontWeight: FontWeight.w600)),
                                ),
                              ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  // Create button — sticky bottom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              for (var c in choiceControllers) {
                                c.dispose();
                              }
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: subTextColor,
                              side: BorderSide(color: divider),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(fontFamily: 'Fredoka', fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final question = questionController.text.trim();
                              final deck = deckController.text.trim().isEmpty
                                  ? 'Default'
                                  : deckController.text.trim();

                              if (question.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a question')),
                                );
                                return;
                              }

                              if (selectedType == 'identification') {
                                final answer = answerController.text.trim();
                                if (answer.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter an answer')),
                                  );
                                  return;
                                }

                                final card = Flashcard(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  question: question,
                                  answer: answer,
                                  type: FlashcardType.identification,
                                  deck: deck,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  reviewCount: 0,
                                  correctCount: 0,
                                  options: [],
                                  correctOptionIndex: 0,
                                );

                                await widget.databaseService.addFlashcard(card);
                              } else {
                                final choices = choiceControllers
                                    .map((c) => c.text.trim())
                                    .where((c) => c.isNotEmpty)
                                    .toList();

                                if (choices.length < 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please add at least 2 choices')),
                                  );
                                  return;
                                }

                                final card = Flashcard(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  question: question,
                                  answer: choices[correctChoiceIndex],
                                  type: FlashcardType.multipleChoice,
                                  deck: deck,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  reviewCount: 0,
                                  correctCount: 0,
                                  options: choices,
                                  correctOptionIndex: correctChoiceIndex,
                                );

                                await widget.databaseService.addFlashcard(card);
                              }

                              if (mounted) {
                                for (var c in choiceControllers) {
                                  c.dispose();
                                }
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Flashcard created!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text('Create Card',
                                style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? _deepPurple.withValues(alpha: isDark ? 0.25 : 0.1)
              : (isDark ? const Color(0xFF2A2A3E) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _deepPurple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? _deepPurple : (isDark ? Colors.white70 : Colors.black54), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? _deepPurple : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to edit an existing flashcard
  void _showEditFlashcardDialog(Flashcard card) {
    final questionController = TextEditingController(text: card.question);
    final answerController = TextEditingController(text: card.answer);
    final deckController = TextEditingController(text: card.deck);
    String selectedType = card.type == FlashcardType.multipleChoice
        ? 'multiple_choice'
        : 'identification';
    List<TextEditingController> choiceControllers = card.options
        .map((option) => TextEditingController(text: option))
        .toList();
    int correctChoiceIndex = card.correctOptionIndex;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _isDark ? const Color(0xFF1F1F2E) : Colors.white,
          title: Text('Edit Flashcard',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: _textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deck Name',
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: _textColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: deckController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Biology 101',
                    hintStyle: TextStyle(color: _subTextColor),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(fontFamily: 'Fredoka', color: _textColor),
                ),
                const SizedBox(height: 16),
                Text('Type',
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: _textColor)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedType == 'multiple_choice' ? 'Multiple Choice' : 'Short Answer',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, color: _textColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Question',
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: _textColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(
                    hintText: 'Enter the question',
                    hintStyle: TextStyle(color: _subTextColor),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(fontFamily: 'Fredoka', color: _textColor),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                if (selectedType == 'identification') ...[
                  Text('Answer',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: _textColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: answerController,
                    decoration: InputDecoration(
                      hintText: 'Enter the answer',
                      hintStyle: TextStyle(color: _subTextColor),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(fontFamily: 'Fredoka', color: _textColor),
                    maxLines: 3,
                  ),
                ] else ...[
                  Text('Choices (max 5)',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, color: _textColor)),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(choiceControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: choiceControllers[index],
                                decoration: InputDecoration(
                                  hintText: 'Choice ${index + 1}',
                                  hintStyle: TextStyle(color: _subTextColor),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                style: TextStyle(fontFamily: 'Fredoka', color: _textColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Radio<int>(
                              value: index,
                              groupValue: correctChoiceIndex,
                              onChanged: (value) {
                                setState(() => correctChoiceIndex = value ?? 0);
                              },
                            ),
                            if (choiceControllers.length > 2)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    choiceControllers[index].dispose();
                                    choiceControllers.removeAt(index);
                                    if (correctChoiceIndex >= choiceControllers.length) {
                                      correctChoiceIndex = choiceControllers.length - 1;
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  if (choiceControllers.length < 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            choiceControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Choice',
                            style: TextStyle(fontFamily: 'Fredoka')),
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                for (var controller in choiceControllers) {
                  controller.dispose();
                }
                Navigator.pop(context);
              },
              child: Text('Cancel',
                  style: TextStyle(fontFamily: 'Fredoka', color: _subTextColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                final question = questionController.text.trim();
                final deck = deckController.text.trim().isEmpty
                    ? 'Default'
                    : deckController.text.trim();

                if (question.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a question')),
                  );
                  return;
                }

                if (selectedType == 'identification') {
                  final answer = answerController.text.trim();
                  if (answer.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an answer')),
                    );
                    return;
                  }

                  final updatedCard = Flashcard(
                    id: card.id,
                    question: question,
                    answer: answer,
                    type: FlashcardType.identification,
                    deck: deck,
                    createdAt: card.createdAt,
                    updatedAt: DateTime.now(),
                    reviewCount: card.reviewCount,
                    correctCount: card.correctCount,
                    options: [],
                    correctOptionIndex: 0,
                  );

                  await widget.databaseService.updateFlashcard(updatedCard);
                } else {
                  final choices = choiceControllers
                      .map((c) => c.text.trim())
                      .where((c) => c.isNotEmpty)
                      .toList();

                  if (choices.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add at least 2 choices')),
                    );
                    return;
                  }

                  final updatedCard = Flashcard(
                    id: card.id,
                    question: question,
                    answer: choices[correctChoiceIndex],
                    type: FlashcardType.multipleChoice,
                    deck: deck,
                    createdAt: card.createdAt,
                    updatedAt: DateTime.now(),
                    reviewCount: card.reviewCount,
                    correctCount: card.correctCount,
                    options: choices,
                    correctOptionIndex: correctChoiceIndex,
                  );

                  await widget.databaseService.updateFlashcard(updatedCard);
                }

                if (mounted) {
                  for (var controller in choiceControllers) {
                    controller.dispose();
                  }
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Flashcard updated!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update',
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(Flashcard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1F1F2E) : Colors.white,
        title: Text('Delete Flashcard?',
            style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: _textColor)),
        content: Text(
          'Are you sure you want to delete "${card.question.length > 50 ? card.question.substring(0, 50) + '...' : card.question}"?',
          style: TextStyle(fontFamily: 'Fredoka', color: _textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(fontFamily: 'Fredoka', color: _subTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.databaseService.deleteFlashcard(card.id);
              if (mounted) {
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flashcard deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
