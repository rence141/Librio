import 'package:flutter/material.dart';
import '../config/ai_plans.dart';
import '../services/ai_usage_service.dart';

/// Compact AI usage details panel.
/// 
/// Displays:
/// - Current context usage
/// - Messages used today
/// - Requests this minute
/// - Current plan
/// - User-friendly limits
class AiUsagePanel extends StatefulWidget {
  final VoidCallback? onClose;

  const AiUsagePanel({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  State<AiUsagePanel> createState() => _AiUsagePanelState();
}

class _AiUsagePanelState extends State<AiUsagePanel> {
  late Future<AiUsageSnapshot?> _usageFuture;
  final _usageService = AiUsageService();

  @override
  void initState() {
    super.initState();
    _usageFuture = _usageService.getCurrentUsage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AiUsageSnapshot?>(
      future: _usageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildErrorState();
        }

        final usage = snapshot.data!;
        return _buildUsagePanel(usage);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage Information',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load usage details, but you can still use AI.\n\nFree Plan:\n• 5 requests per minute\n• 30 requests per hour\n• 100 messages per day',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsagePanel(AiUsageSnapshot usage) {
    final limits = usage.planLimits;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Usage',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (widget.onClose != null)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Context usage
          _buildUsageRow(
            label: 'Context',
            current: usage.totalInputTokensThisDay,
            max: limits.maxInputTokens,
            unit: 'tokens',
            percent: usage.contextUsagePercent,
            isWarning: usage.isContextWarning,
            isCritical: usage.isContextCritical,
          ),
          const SizedBox(height: 12),

          // Messages today
          _buildUsageRow(
            label: 'Messages',
            current: usage.messagesThisDay,
            max: limits.messagesPerDay,
            unit: 'today',
            percent: (usage.messagesThisDay / limits.messagesPerDay) * 100,
          ),
          const SizedBox(height: 12),

          // Requests this minute
          _buildUsageRow(
            label: 'Requests',
            current: usage.requestsThisMinute,
            max: limits.requestsPerMinute,
            unit: 'this minute',
            percent: (usage.requestsThisMinute / limits.requestsPerMinute) * 100,
          ),
          const SizedBox(height: 16),

          // Plan info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plan',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  limits.displayName,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: usage.currentPlan == AiPlan.paid
                        ? const Color(0xFF7B2CBF)
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Upgrade hint for free users
          if (usage.currentPlan == AiPlan.free)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2CBF).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF7B2CBF).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: const Color(0xFF7B2CBF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upgrade to Paid for higher limits',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 12,
                          color: const Color(0xFF7B2CBF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsageRow({
    required String label,
    required int current,
    required int max,
    required String unit,
    required double percent,
    bool isWarning = false,
    bool isCritical = false,
  }) {
    final color = isCritical
        ? Colors.red[600]
        : isWarning
            ? Colors.orange[600]
            : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$current / $max $unit',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0, 1),
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isCritical
                  ? Colors.red[500]!
                  : isWarning
                      ? Colors.orange[500]!
                      : const Color(0xFF06B6D4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Show AI usage panel in a bottom sheet
void showAiUsagePanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AiUsagePanel(
          onClose: () => Navigator.pop(context),
        ),
      ),
    ),
  );
}
