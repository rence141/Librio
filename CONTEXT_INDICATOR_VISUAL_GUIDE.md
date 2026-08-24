# Context Indicator Visual Guide

**Date**: 2026-08-24
**Status**: ✅ COMPLETE

---

## Composer Layout

### Full View
```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  [Attach]  [Text Input Field]  [Context]  [Send Button]   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Detailed Layout
```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  [📎]  [Type your message here...]  [50%]  [↑]            │
│  Attach                             Context Send           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Indicator States

### State 1: Normal Usage (0-74%)

```
┌──────┐
│ 0%   │  ← Purple border, light purple background
└──────┘

┌──────┐
│ 25%  │  ← Purple border, light purple background
└──────┘

┌──────┐
│ 50%  │  ← Purple border, light purple background
└──────┘

┌──────┐
│ 74%  │  ← Purple border, light purple background
└──────┘
```

**Visual**: Calm, normal state
**Color**: Deep purple (#7B2CBF)
**Meaning**: Plenty of context available

---

### State 2: Warning (75-89%)

```
┌──────┐
│ 75%  │  ← Orange border, light orange background
└──────┘

┌──────┐
│ 80%  │  ← Orange border, light orange background
└──────┘

┌──────┐
│ 85%  │  ← Orange border, light orange background
└──────┘

┌──────┐
│ 89%  │  ← Orange border, light orange background
└──────┘
```

**Visual**: Cautionary, approaching limit
**Color**: Orange (#F97316)
**Meaning**: Context getting full, consider starting new chat

---

### State 3: Critical (90-100%)

```
┌──────┐
│ 90%  │  ← Red border, light red background
└──────┘

┌──────┐
│ 95%  │  ← Red border, light red background
└──────┘

┌──────┐
│100%  │  ← Red border, light red background
└──────┘
```

**Visual**: Alert, limit reached
**Color**: Red (#DC2626)
**Meaning**: Context full, must start new chat

---

## Size Comparison

### Indicator Size
```
32x32 pixels

┌──────────────────────────────────────┐
│                                      │
│  ┌──────┐                            │
│  │ 50%  │  ← Indicator               │
│  └──────┘                            │
│                                      │
│  32px × 32px                         │
│                                      │
└──────────────────────────────────────┘
```

### Comparison with Other Elements
```
Send Button:  44x44 px
Indicator:    32x32 px  (27% smaller)
Text Input:   ~200px wide

Layout:
[Text Input ~200px] [Indicator 32px] [Send 44px]
```

---

## Spacing

### Horizontal Spacing
```
[Text Field] ← 4px → [Indicator] ← 4px → [Send Button]
              ↑                          ↑
              Minimal spacing            Minimal spacing
              (reduced from 8px)         (reduced from 8px)
```

### Vertical Alignment
```
┌──────────────────────────────────────┐
│                                      │
│  [Text]  [Indicator]  [Send]         │
│  ↑       ↑            ↑              │
│  Centered vertically with send button│
│                                      │
└──────────────────────────────────────┘
```

---

## Color Palette

### Purple (Normal)
```
Border:     #7B2CBF (Deep Purple)
Text:       #7B2CBF (Deep Purple)
Background: #F3E5F5 (Light Purple)

Visual:
┌──────┐
│ 50%  │  ← Purple text on light purple background
└──────┘     with purple border
```

### Orange (Warning)
```
Border:     #F97316 (Orange)
Text:       #B45309 (Dark Orange)
Background: #FEF3C7 (Light Orange)

Visual:
┌──────┐
│ 80%  │  ← Dark orange text on light orange background
└──────┘     with orange border
```

### Red (Critical)
```
Border:     #DC2626 (Red)
Text:       #B91C1C (Dark Red)
Background: #FEE2E2 (Light Red)

Visual:
┌──────┐
│ 95%  │  ← Dark red text on light red background
└──────┘     with red border
```

---

## Interaction States

### Default State
```
┌──────┐
│ 50%  │  ← Normal appearance
└──────┘
```

### Hover State
```
┌──────┐
│ 50%  │  ← Tooltip appears above
└──────┘
  ↑
  "Context: 50% | Requests: 12 remaining"
```

### Pressed State
```
┌──────┐
│ 50%  │  ← Ripple effect (Material Design)
└──────┘
  ↓
  Opens detailed usage panel
```

---

## Responsive Behavior

### Small Screen (Mobile)
```
Width: 320px
┌────────────────────────────────────┐
│ [Text]  [32]  [↑]                  │
└────────────────────────────────────┘
✓ Fits comfortably
✓ Doesn't crowd composer
```

### Medium Screen (Tablet)
```
Width: 600px
┌──────────────────────────────────────────────┐
│ [Text Input]      [32]      [↑]              │
└──────────────────────────────────────────────┘
✓ Scales proportionally
✓ Maintains visual balance
```

### Large Screen (Desktop)
```
Width: 1000px
┌────────────────────────────────────────────────────────────┐
│ [Text Input]           [32]           [↑]                  │
└────────────────────────────────────────────────────────────┘
✓ Remains compact
✓ Doesn't dominate UI
```

---

## Tooltip Display

### Tooltip Format
```
┌─────────────────────────────────────┐
│ Context: 50% | Requests: 12 remaining│
└─────────────────────────────────────┘
         ↓
      ┌──────┐
      │ 50%  │
      └──────┘
```

### Tooltip Content
```
"Context: 0% | Requests: 15 remaining"
"Context: 50% | Requests: 12 remaining"
"Context: 75% | Requests: 10 remaining"
"Context: 90% | Requests: 8 remaining"
"Context: 100% | Requests: 5 remaining"
```

---

## Usage Panel Integration

### Tap Behavior
```
User taps indicator
        ↓
Detailed usage panel opens
        ↓
Shows:
- Context usage (percentage)
- Messages today
- Requests remaining
- Current plan
- Upgrade option (if free user)
```

### Panel Content
```
┌─────────────────────────────────────┐
│ AI Usage                            │
├─────────────────────────────────────┤
│ Context: 50% (8K / 16K tokens)      │
│ Messages: 12 / 100 today            │
│ Requests: 12 remaining              │
│ Plan: Free                          │
├─────────────────────────────────────┤
│ [Upgrade to Pro]                    │
└─────────────────────────────────────┘
```

---

## Animation Behavior

### Color Transition
```
Normal (Purple)
    ↓
    (Smooth transition when usage reaches 75%)
    ↓
Warning (Orange)
    ↓
    (Smooth transition when usage reaches 90%)
    ↓
Critical (Red)
```

**Note**: No animated progress border (unlike previous design)
**Reason**: Keeps indicator simple and lightweight

---

## Accessibility

### Touch Target
```
Minimum size: 32x32 px (meets Material Design)
Recommended: 44x44 px (for comfortable touch)
Actual: 32x32 px (with 4px padding = 40x40 effective)
```

### Visual Contrast
```
Purple on Light Purple:  ✓ High contrast
Orange on Light Orange: ✓ High contrast
Red on Light Red:       ✓ High contrast
```

### Semantic Information
```
Tooltip: "Context: 50% | Requests: 12 remaining"
Color:   Purple (normal), Orange (warning), Red (critical)
Text:    Clear percentage display
```

---

## Best Practices

### ✅ Do
- Show indicator only when using online model
- Update color based on usage level
- Provide tooltip on hover
- Open usage panel on tap
- Use consistent spacing
- Maintain responsive design

### ❌ Don't
- Show indicator when using local model
- Use confusing colors
- Hide tooltip information
- Make indicator too large
- Add unnecessary animations
- Use inconsistent spacing

---

## Summary

The **CompactContextIndicator** is:

✅ **Compact** — 32x32 px, minimal visual footprint
✅ **Clear** — Percentage text at a glance
✅ **Color-Coded** — Visual feedback for usage levels
✅ **Interactive** — Tap for detailed info
✅ **Responsive** — Works on all screen sizes
✅ **Professional** — Matches Librio's design
✅ **Accessible** — Proper touch targets and tooltips

It provides **context usage feedback without crowding the message composer**.
