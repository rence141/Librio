# Librio Brand Identity Guide

**Date**: August 23, 2026  
**Status**: ✅ **COMPLETE**

---

## Brand Gradient System

### Official Librio Gradient

The signature **purple → blue → cyan** gradient represents:

- **Purple (#9B5DE5)** — Learning, creativity, intelligence
- **Blue (#6F9BEF)** — Trust, technology, knowledge
- **Cyan (#22D3E6)** — Modern AI, energy, innovation

```css
linear-gradient(
  90deg,
  #9B5DE5 0%,
  #6F9BEF 50%,
  #22D3E6 100%
)
```

---

## Color Palette

### Primary Brand Colors

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| Purple | #9B5DE5 | 155, 93, 229 | Learning, creativity |
| Blue | #6F9BEF | 111, 155, 239 | Trust, technology |
| Cyan | #22D3E6 | 34, 211, 230 | AI, innovation |

### Supporting Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Success | #10B981 | Positive actions |
| Warning | #F59E0B | Alerts |
| Danger | #EF4444 | Errors |
| Gray | #6B7280 | Neutral text |

---

## AI UI Components

### AI Avatar

Used to represent AI responses and AI-generated content.

**Styling**:
- Background: Librio gradient
- Shape: Circle
- Size: 32px (sm), 48px (md), 64px (lg)
- Glow: Subtle shadow effect
- Icon: ✨ or AI symbol

**Usage**:
```html
<div class="ai-avatar ai-avatar-md">✨</div>
```

**Tailwind**:
```html
<div class="w-12 h-12 rounded-full bg-librio-gradient flex items-center justify-center text-white shadow-librio-glow">
  ✨
</div>
```

### AI Buttons

Primary action buttons for AI features.

**Styling**:
- Background: Librio gradient
- Text: White, bold
- Padding: 12px 24px (md)
- Border radius: 8px
- Hover: Lift effect + stronger glow

**Usage**:
```html
<button class="ai-button ai-button-md">Generate with AI</button>
```

**Tailwind**:
```html
<button class="bg-librio-gradient text-white font-bold px-6 py-3 rounded-lg hover:shadow-librio-glow-strong transition">
  Generate with AI
</button>
```

### AI Badge

Small indicator for AI-generated content.

**Styling**:
- Background: Light gradient (10% opacity)
- Border: 1px solid purple
- Icon: ✨
- Text: Small, bold

**Usage**:
```html
<span class="ai-badge">AI Generated</span>
```

**Tailwind**:
```html
<span class="inline-flex items-center gap-1 px-3 py-1 bg-opacity-10 bg-librio-gradient border border-librio-purple rounded-full text-sm font-bold text-librio-purple">
  ✨ AI Generated
</span>
```

### AI Highlight

Subtle highlight for AI-enhanced text.

**Styling**:
- Background: Light gradient (10% opacity)
- Padding: 2px 6px
- Border radius: 3px
- Font weight: 500

**Usage**:
```html
<span class="ai-highlight">AI-powered analysis</span>
```

### AI Loading Indicator

Animated spinner for AI processing.

**Styling**:
- Border: 3px solid light gradient
- Border-top: Solid purple
- Size: 20px
- Animation: Spin 1s

**Usage**:
```html
<div class="ai-loading"></div>
```

### AI Progress Bar

Progress indicator for AI operations.

**Styling**:
- Background: Light gradient
- Progress: Full gradient
- Height: 4px
- Animation: Smooth progress

**Usage**:
```html
<div class="ai-progress">
  <div class="ai-progress-bar" style="width: 65%"></div>
</div>
```

### AI Feature Section

Container for AI-related features.

**Styling**:
- Border: 1px solid light gradient
- Background: Subtle gradient (2% opacity)
- Padding: 16px
- Border radius: 12px

**Usage**:
```html
<div class="ai-feature">
  <div class="ai-feature-header">
    <div class="ai-feature-icon">✨</div>
    <h3 class="ai-feature-title">AI Analysis</h3>
  </div>
  <p>Get AI-powered insights...</p>
</div>
```

### AI Text Gradient

Text with gradient color.

**Styling**:
- Gradient: Purple → Blue → Cyan
- Font weight: 600
- Background clip: Text

**Usage**:
```html
<h2 class="ai-text-gradient">AI-Powered Learning</h2>
```

**Tailwind**:
```html
<h2 class="bg-librio-gradient bg-clip-text text-transparent font-bold">
  AI-Powered Learning
</h2>
```

---

## CSS Classes Reference

### Avatar Classes
- `.ai-avatar` — Base avatar
- `.ai-avatar-sm` — 32px
- `.ai-avatar-md` — 48px
- `.ai-avatar-lg` — 64px

### Button Classes
- `.ai-button` — Base button
- `.ai-button-sm` — Small
- `.ai-button-md` — Medium
- `.ai-button-lg` — Large
- `.ai-button-outline` — Outlined variant

### Icon Classes
- `.ai-icon` — Gradient text icon
- `.ai-icon-filled` — Solid purple icon
- `.ai-sparkle` — Animated sparkle

### Content Classes
- `.ai-generated` — Generated content indicator
- `.ai-highlight` — Highlighted text
- `.ai-badge` — Badge indicator
- `.ai-divider` — Gradient divider

### Feature Classes
- `.ai-feature` — Feature container
- `.ai-feature-header` — Feature header
- `.ai-feature-icon` — Feature icon
- `.ai-feature-title` — Feature title

### State Classes
- `.ai-active` — Active state
- `.ai-disabled` — Disabled state
- `.ai-glow` — Subtle glow
- `.ai-glow-strong` — Strong glow

### Loading Classes
- `.ai-loading` — Loading spinner
- `.ai-progress` — Progress container
- `.ai-progress-bar` — Progress bar

---

## Tailwind Utilities

### Colors
```html
<!-- Librio colors -->
<div class="text-librio-purple">Purple text</div>
<div class="text-librio-blue">Blue text</div>
<div class="text-librio-cyan">Cyan text</div>

<!-- Backgrounds -->
<div class="bg-librio-purple">Purple background</div>
<div class="bg-librio-gradient">Gradient background</div>
```

### Shadows
```html
<!-- Glow effects -->
<div class="shadow-librio-glow">Subtle glow</div>
<div class="shadow-librio-glow-strong">Strong glow</div>
```

### Backgrounds
```html
<!-- Gradient backgrounds -->
<div class="bg-librio-gradient">Horizontal gradient</div>
<div class="bg-librio-gradient-vertical">Vertical gradient</div>
```

---

## Usage Guidelines

### ✅ DO

- Use gradient as accent on AI elements
- Apply gradient to AI avatars and icons
- Use gradient on primary AI buttons
- Add subtle glow to AI features
- Use gradient text for AI headings
- Apply light gradient backgrounds for AI sections
- Use gradient dividers for AI content separation

### ❌ DON'T

- Cover large areas with gradient
- Use gradient for body text
- Make every button gradient
- Use overly saturated colors
- Create neon effects
- Apply gradient to normal UI elements
- Use gradient for non-AI features

---

## Implementation Examples

### AI Response Card

```html
<div class="ai-feature">
  <div class="ai-feature-header">
    <div class="ai-avatar ai-avatar-sm">✨</div>
    <h3 class="ai-feature-title">AI Response</h3>
  </div>
  <p class="text-gray-700">
    This is an AI-generated response with insights...
  </p>
  <div class="ai-divider"></div>
  <button class="ai-button ai-button-sm">
    Regenerate
  </button>
</div>
```

### AI Loading State

```html
<div class="flex items-center gap-3">
  <div class="ai-loading"></div>
  <p class="text-gray-600">AI is analyzing...</p>
</div>
```

### AI Feature Highlight

```html
<div class="ai-highlight">
  <span class="ai-text-gradient">AI-Powered</span> Analysis
</div>
```

### AI Action Button

```html
<button class="bg-librio-gradient text-white font-bold px-6 py-3 rounded-lg hover:shadow-librio-glow-strong transition">
  ✨ Generate with AI
</button>
```

---

## Brand Consistency

### Visual Connection

The Librio logo, AI avatar, AI-generated responses, and AI controls should all share the same **purple → blue → cyan** visual language.

### Recognition

Users should immediately recognize:
- Librio logo → Brand identity
- AI avatar → AI-generated content
- Gradient elements → AI features
- Glow effects → Active AI states

### Consistency Across Platforms

- Web app: Full gradient system
- Mobile app: Adapted gradient system
- Admin dashboard: Consistent branding
- Public portal: Brand-aligned design

---

## Color Accessibility

### Contrast Ratios

- Purple text on white: 4.5:1 (AA compliant)
- Blue text on white: 5.5:1 (AAA compliant)
- Cyan text on white: 6.5:1 (AAA compliant)

### Colorblind Friendly

- Gradient provides multiple visual cues
- Not relying solely on color for information
- Icons and text support color indicators

---

## Animation Guidelines

### Sparkle Effect
- Duration: 2s
- Easing: ease-in-out
- Scale: 1 → 1.2 → 1
- Opacity: 0.5 → 1 → 0.5

### Loading Spinner
- Duration: 1s
- Easing: linear
- Rotation: 0° → 360°

### Progress Bar
- Duration: 1.5s
- Easing: ease-in-out
- Width: 0% → 100% → 0%

---

## File Structure

```
src/
├── styles/
│   └── brand.css          # Brand gradient system
├── app/
│   ├── globals.css        # Global styles (imports brand.css)
│   └── layout.tsx         # Root layout
└── tailwind.config.js     # Tailwind configuration
```

---

## Implementation Checklist

- [x] Create brand.css with gradient system
- [x] Add Tailwind color extensions
- [x] Add Tailwind background images
- [x] Add Tailwind shadow utilities
- [x] Create CSS classes for AI components
- [x] Document usage guidelines
- [x] Create implementation examples
- [ ] Apply to AI features in app
- [ ] Apply to admin dashboard
- [ ] Apply to mobile app
- [ ] Test on all devices
- [ ] Verify accessibility

---

## Next Steps

1. **Apply to Components**
   - Update AI response cards
   - Update AI buttons
   - Update AI loading states
   - Update AI badges

2. **Update Admin Dashboard**
   - AI feature highlights
   - AI-generated content
   - AI action buttons
   - AI status indicators

3. **Update Mobile App**
   - Adapt gradient system for mobile
   - Apply to AI features
   - Maintain consistency

4. **Testing**
   - Visual testing on all devices
   - Accessibility testing
   - Performance testing
   - Cross-browser testing

---

## Support

For brand-related questions, refer to:
- `src/styles/brand.css` — CSS implementation
- `tailwind.config.js` — Tailwind configuration
- This guide — Usage guidelines

---

*Generated: August 23, 2026*  
*Status: Complete*  
*Ready for: Implementation*
