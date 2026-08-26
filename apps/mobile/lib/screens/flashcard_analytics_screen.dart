import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/database_service.dart';

/// Separate analytics page showing flashcard performance metrics.
class FlashcardAnalyticsScreen extends StatelessWidget {
  final List<Flashcard> cards;
  final List<String> decks;
  final DatabaseService databaseService;

  const FlashcardAnalyticsScreen({
    super.key,
    required this.cards,
    required this.decks,
    required this.databaseService,
  });

  // Colors
  static const Color _deepPurple = Color(0xFF7B2CBF);
  static const Color _cyan = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardBg = isDark ? const Color(0xFF1F1F2E) : Colors.white;
    final divider = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    // Calculate metrics
    final totalCards = cards.length;
    final reviewedCards = cards.where((c) => c.reviewCount > 0).toList();
    final totalReviews = cards.fold<int>(0, (sum, c) => sum + c.reviewCount);
    final totalCorrect = cards.fold<int>(0, (sum, c) => sum + c.correctCount);
    final accuracy = totalReviews > 0 ? (totalCorrect / totalReviews * 100).round() : 0;
    final masteredCards = reviewedCards.where((c) {
      if (c.reviewCount == 0) return false;
      return (c.correctCount / c.reviewCount) >= 0.7;
    }).length;
    final masteryPercent = totalCards > 0 ? (masteredCards / totalCards * 100).round() : 0;
    final cardsToReview = totalCards - masteredCards;

    // Per-tag performance
    final tagStats = <String, _TagStat>{};
    for (final card in cards) {
      for (final tag in card.tags) {
        final stat = tagStats.putIfAbsent(tag, () => _TagStat());
        stat.total++;
        if (card.reviewCount > 0) {
          stat.reviewed++;
          stat.correct += card.correctCount;
          stat.reviews += card.reviewCount;
        }
      }
    }

    final strongAreas = <MapEntry<String, int>>[];
    final needsPractice = <MapEntry<String, int>>[];
    for (final entry in tagStats.entries) {
      final stat = entry.value;
      if (stat.reviews == 0) continue;
      final tagAccuracy = (stat.correct / stat.reviews * 100).round();
      if (tagAccuracy >= 70) {
        strongAreas.add(MapEntry(entry.key, tagAccuracy));
      } else {
        needsPractice.add(MapEntry(entry.key, tagAccuracy));
      }
    }

    // Per-deck performance
    final deckStats = <String, _TagStat>{};
    for (final card in cards) {
      final stat = deckStats.putIfAbsent(card.deck, () => _TagStat());
      stat.total++;
      if (card.reviewCount > 0) {
        stat.reviewed++;
        stat.correct += card.correctCount;
        stat.reviews += card.reviewCount;
      }
    }

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
          'Flashcard Analytics',
          style: TextStyle(
            fontFamily: 'Fredoka',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: totalCards == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: _deepPurple.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No analytics yet',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review some flashcards to see performance metrics.',
                    style: TextStyle(fontFamily: 'Fredoka', color: subTextColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mastery card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: divider, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics, size: 18, color: _deepPurple),
                            const SizedBox(width: 8),
                            Text(
                              'Flashcard Performance',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Mastery circle + label
                        Row(
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: masteryPercent / 100,
                                    strokeWidth: 7,
                                    backgroundColor: divider,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      masteryPercent >= 70 ? Colors.green : _deepPurple,
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '$masteryPercent%',
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mastery',
                                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, color: subTextColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$masteredCards / $totalCards Cards Mastered',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalCards > 0 ? masteredCards / totalCards : 0,
                            minHeight: 8,
                            backgroundColor: divider,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              masteryPercent >= 70 ? Colors.green : _deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Metrics grid
                  Row(
                    children: [
                      _buildMetricCard('Accuracy', '$accuracy%', Icons.gpp_good, cardBg, divider, textColor, subTextColor),
                      const SizedBox(width: 12),
                      _buildMetricCard('Cards to Review', '$cardsToReview', Icons.replay, cardBg, divider, textColor, subTextColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricCard('Total Reviews', '$totalReviews', Icons.repeat, cardBg, divider, textColor, subTextColor),
                      const SizedBox(width: 12),
                      _buildMetricCard('Decks', '${decks.length}', Icons.folder, cardBg, divider, textColor, subTextColor),
                    ],
                  ),
                  // Per-deck breakdown
                  if (deckStats.length > 1) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Deck Breakdown',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...deckStats.entries.map((entry) {
                      final stat = entry.value;
                      final deckAccuracy = stat.reviews > 0 ? (stat.correct / stat.reviews * 100).round() : 0;
                      return _buildDeckRow(entry.key, stat.total, stat.reviewed, deckAccuracy, cardBg, divider, textColor, subTextColor);
                    }),
                  ],
                  // Strong areas
                  if (strongAreas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Strong Areas',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: strongAreas.map((e) => _buildAreaChip(e.key, e.value, true)).toList(),
                    ),
                  ],
                  // Needs practice
                  if (needsPractice.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Needs Practice',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: needsPractice.map((e) => _buildAreaChip(e.key, e.value, false)).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color cardBg, Color divider, Color textColor, Color subTextColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: divider, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: _deepPurple, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: subTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckRow(String deck, int total, int reviewed, int accuracy, Color cardBg, Color divider, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: divider, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.folder_outlined, size: 18, color: _deepPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                deck,
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            Text(
              '$reviewed/$total reviewed',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: subTextColor),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accuracy >= 70
                    ? Colors.green.withValues(alpha: 0.15)
                    : accuracy >= 50
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$accuracy%',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accuracy >= 70 ? Colors.green : accuracy >= 50 ? Colors.orange : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaChip(String tag, int accuracy, bool isStrong) {
    final color = isStrong ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStrong ? Icons.check_circle : Icons.warning_amber,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            tag,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$accuracy%',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagStat {
  int total = 0;
  int reviewed = 0;
  int correct = 0;
  int reviews = 0;
}
