import 'package:flutter/material.dart';

/// Compact square context usage indicator for the chat composer.
/// 
/// Displays the current context usage percentage in a tiny, unobtrusive square.
/// Designed to fit seamlessly next to the send button without crowding the UI.
/// 
/// Features:
/// - Compact 32x32 size (same as icon button)
/// - Square shape with subtle rounded corners
/// - Percentage text centered
/// - Color-coded based on usage level:
///   * Normal (0-74%): Purple border
///   * Warning (75-89%): Orange border
///   * Critical (90-100%): Red border
/// - Minimal padding and spacing
/// - Tappable to show detailed usage info
/// - Hides when context usage is not relevant
class CompactContextIndicator extends StatelessWidget {
  final double usage; // 0.0 to 1.0
  final VoidCallback? onTap;
  final String? tooltip;

  const CompactContextIndicator({
    Key? key,
    required this.usage,
    this.onTap,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = (usage * 100).toStringAsFixed(0);
    final percentValue = usage * 100;
    
    // Determine color based on usage level
    final (borderColor, textColor, backgroundColor) = _getColors(percentValue);

    return Tooltip(
      message: tooltip ?? 'Context: $percent%',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              percent,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.0, // Tight line height for compact display
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get colors based on usage level
  (Color borderColor, Color textColor, Color backgroundColor) _getColors(
    double percentValue,
  ) {
    if (percentValue >= 90) {
      // Critical: Red
      return (
        Colors.red[600]!,
        Colors.red[700]!,
        Colors.red[50]!,
      );
    } else if (percentValue >= 75) {
      // Warning: Orange
      return (
        Colors.orange[600]!,
        Colors.orange[700]!,
        Colors.orange[50]!,
      );
    } else {
      // Normal: Purple
      return (
        const Color(0xFF7B2CBF), // Deep purple
        const Color(0xFF7B2CBF),
        const Color(0xFFF3E5F5), // Light purple background
      );
    }
  }
}
