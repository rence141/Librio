# Compact Context Indicator Design

**Date**: 2026-08-24
**Status**: ✅ COMPLETE

---

## Overview

Redesigned the context usage indicator to be a **tiny, compact, square-shaped element** that fits seamlessly into the message composer without visual clutter.

---

## Design Goals

✅ **Compact** — Minimal visual footprint
✅ **Square-shaped** — Native, icon-like appearance
✅ **Unobtrusive** — Doesn't compete with text field or send button
✅ **Informative** — Clear percentage display
✅ **Color-coded** — Visual feedback for usage levels
✅ **Professional** — Consistent with Librio's minimalist design
✅ **Accessible** — Tappable for detailed information
✅ **Responsive** — Works on small Android screens

---

## Visual Specifications

### Size
- **Width**: 32px
- **Height**: 32px
- **Padding**: Minimal (4px on each side)
- **Comparison**: Same size as a small icon button

### Shape
- **Style**: Square with rounded corners
- **Border Radius**: 6px
- **Border Width**: 1.5px

### Typography
- **Font**: Fredoka (matches app)
- **Size**: 10pt
- **Weight**: Bold
- **Color**: Dynamic based on usage level
- **Line Height**: 1.0 (tight for compact display)

### Spacing
- **Left margin**: 4px (reduced from 8px)
- **Right margin**: 4px (reduced from 8px)
- **Placement**: Between text field and send button

---

## Color Scheme

### Normal Usage (0-74%)
```
Border Color:       #7B2CBF (Deep Purple)
Text Color:         #7B2CBF (Deep Purple)
Background Color:   #F3E5F5 (Light Purple)
```

### Warning (75-89%)
```
Border Color:       #F97316 (Orange)
Text Color:         #B45309 (Dark Orange)
Background Color:   #FEF3C7 (Light Orange)
```

### Critical (90-100%)
```
Border Color:       #DC2626 (Red)
Text Color:         #B91C1C (Dark Red)
Background Color:   #FEE2E2 (Light Red)
```

---

## Content Display

### Percentage Format
- **0%** → "0%"
- **12%** → "12%"
- **50%** → "50%"
- **85%** → "85%"
- **100%** → "100%"

### Tooltip
On hover or long-press:
```
"Context: 85% | Requests: 12 remaining"
```

---

## Interaction

### Tap Behavior
- **Action**: Opens detailed usage information panel
- **Feedback**: Ripple effect (native Material Design)
- **Tooltip**: Shows on hover/long-press

### Visibility
- **Show**: Only when using online model
- **Hide**: When using local model
- **Hide**: When not relevant

---

## Component Implementation

### File
```
apps/mobile/lib/widgets/compact_context_indicator.dart
```

### Class
```dart
class CompactContextIndicator extends StatelessWidget {
  final double usage;        // 0.0 to 1.0
  final VoidCallback? onTap;
  final String? tooltip;
}
```

### Key Features
- Stateless widget (no animation overhead)
- Color selection based on usage percentage
- Tight padding for compact display
- Tooltip support
- Tap handler for detailed info

---

## Integration

### Location
Message composer, between text field and send button:

```
┌─────────────────────────────────────────┐
│ [Text Field]  [Context]  [Send Button]  │
└─────────────────────────────────────────┘
```

### Spacing
- **Left**: 4px (from text field)
- **Right**: 4px (to send button)
- **Vertical**: Centered with send button

### Replacement
- **Replaced**: `ContextMeter` (44x44 rounded-square with progress border)
- **Reason**: Too large, visually distracting
- **Benefit**: 27% smaller, less visual clutter

---

## Before & After

### Before (ContextMeter)
```
Size:           44x44 px
Visual Style:   Progress border (animated)
Spacing:        8px left, 8px right
Appearance:     Prominent, attention-drawing
Use Case:       Detailed context visualization
```

### After (CompactContextIndicator)
```
Size:           32x32 px
Visual Style:   Simple square with percentage
Spacing:        4px left, 4px right
Appearance:     Subtle, unobtrusive
Use Case:       Quick context status check
```

---

## Color Feedback System

### Visual Progression

```
Usage: 0%
┌──────┐
│  0%  │  ← Purple border, light purple background
└──────┘

Usage: 50%
┌──────┐
│ 50%  │  ← Purple border, light purple background
└──────┘

Usage: 75% (Warning threshold)
┌──────┐
│ 75%  │  ← Orange border, light orange background
└──────┘

Usage: 90% (Critical threshold)
┌──────┐
│ 90%  │  ← Red border, light red background
└──────┘

Usage: 100%
┌──────┐
│100%  │  ← Red border, light red background
└──────┘
```

---

## Responsive Design

### Small Screens (Android)
- ✅ 32x32 size fits comfortably
- ✅ 4px spacing doesn't crowd composer
- ✅ Text remains readable at 10pt
- ✅ Tap target large enough (32x32 minimum)

### Medium Screens
- ✅ Scales proportionally
- ✅ Maintains visual balance

### Large Screens
- ✅ Remains compact and unobtrusive
- ✅ Doesn't dominate the UI

---

## Accessibility

### Touch Target
- **Size**: 32x32 px (meets Material Design minimum)
- **Spacing**: 4px from adjacent elements
- **Feedback**: Ripple effect on tap

### Visual Feedback
- **Color**: High contrast borders
- **Text**: Bold, readable at 10pt
- **Tooltip**: Provides context on interaction

### Screen Readers
- **Tooltip**: Provides semantic meaning
- **Interaction**: Standard tap gesture

---

## Usage Example

```dart
// In chat_screen.dart
if (_currentModelIsOnline)
  CompactContextIndicator(
    usage: _contextWindow.usagePercentage / 100.0,
    tooltip: 'Context: ${_contextWindow.usagePercentage.toStringAsFixed(0)}% | Requests: ${_lastRateLimitRemaining ?? "?"} remaining',
    onTap: () => showAiUsagePanel(context),
  ),
```

---

## Design Principles Applied

### Minimalism
- Smallest possible visual footprint
- Only essential information (percentage)
- No unnecessary decoration

### Clarity
- Clear percentage display
- Color-coded status
- Tooltip for additional context

### Consistency
- Matches Librio's design language
- Uses app colors (purple, orange, red)
- Follows Material Design guidelines

### Usability
- Tappable for detailed info
- Visible only when relevant
- Doesn't interfere with primary interaction (text input)

### Professional
- Clean, modern appearance
- Subtle, not flashy
- Appropriate for academic app

---

## Performance

### Rendering
- Stateless widget (no state management)
- Simple Container with Text
- No animations (lightweight)
- No expensive operations

### Memory
- Minimal memory footprint
- No state to maintain
- No listeners or subscriptions

### Efficiency
- Fast rebuild on usage change
- No unnecessary repaints
- Efficient color selection

---

## Future Enhancements

### Optional
- Animated transition when color changes (warning → critical)
- Micro-animation on tap
- Haptic feedback on warning threshold
- Detailed tooltip with more information

### Not Implemented (Keep Simple)
- Progress animation
- Gradient effects
- Complex interactions
- Additional UI elements

---

## Testing

### Visual Testing
- [x] Displays correctly at 0%
- [x] Displays correctly at 50%
- [x] Displays correctly at 75% (warning)
- [x] Displays correctly at 90% (critical)
- [x] Displays correctly at 100%
- [x] Color changes appropriately
- [x] Text remains readable
- [x] Fits in composer without crowding

### Interaction Testing
- [x] Tap opens usage panel
- [x] Tooltip displays on hover
- [x] Hides when using local model
- [x] Shows when using online model

### Responsive Testing
- [x] Looks good on small screens
- [x] Looks good on medium screens
- [x] Looks good on large screens
- [x] Touch target is adequate

---

## Git Commit

```
31369f5 — Redesign context indicator to be compact and square-shaped
```

---

## Summary

The new **CompactContextIndicator** provides:

✅ **Compact Design** — 32x32 px, doesn't crowd the composer
✅ **Clear Information** — Percentage at a glance
✅ **Visual Feedback** — Color-coded status (purple/orange/red)
✅ **Professional Appearance** — Matches Librio's minimalist design
✅ **Full Functionality** — Tap to see detailed usage info
✅ **Responsive** — Works on all screen sizes
✅ **Accessible** — Proper touch targets and tooltips

The indicator is now **unobtrusive yet informative**, providing context usage feedback without competing with the message input or send button.
