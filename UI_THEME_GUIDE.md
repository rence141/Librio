# Librio UI Theme Guide

**Status:** ✅ Official Theme Implemented  
**Date:** 2026-08-22  
**Theme:** Modern Gradient Design

---

## 🎨 Official Color Palette

### Primary Gradient (Left → Right)

```
Deep Purple → Indigo → Bright Blue → Cyan
```

| Color Name | Hex Code | RGB | Position |
|-----------|----------|-----|----------|
| Deep Purple | #7B2CBF | 123, 44, 191 | Start (0%) |
| Indigo | #4F46E5 | 79, 70, 229 | 33% |
| Bright Blue | #3B82F6 | 59, 130, 246 | 66% |
| Cyan | #06B6D4 | 6, 182, 212 | End (100%) |

### Supporting Colors

| Color Name | Hex Code | RGB | Usage |
|-----------|----------|-----|-------|
| Soft White | #F8FAFC | 248, 250, 252 | Background |
| White | #FFFFFF | 255, 255, 255 | Text on gradient |
| Deep Navy | #1E293B | 30, 41, 59 | Alternative text |

---

## 📱 Component Styling

### AppBar

**Style:** Gradient background with white text

```dart
AppBar(
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF7B2CBF), // Deep Purple
          Color(0xFF4F46E5), // Indigo
          Color(0xFF3B82F6), // Bright Blue
          Color(0xFF06B6D4), // Cyan
        ],
        stops: [0.0, 0.33, 0.66, 1.0],
      ),
    ),
  ),
  title: Text('Librio', style: TextStyle(color: Colors.white)),
)
```

**Features:**
- ✅ Smooth gradient transition
- ✅ White text for contrast
- ✅ Professional appearance
- ✅ Consistent branding

### Buttons

**Style:** Gradient with shadow effect

```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF7B2CBF), // Deep Purple
        Color(0xFF06B6D4), // Cyan
      ],
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF7B2CBF).withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: IconButton(
    icon: const Icon(Icons.send),
    color: Colors.white,
    onPressed: onPressed,
  ),
)
```

**Features:**
- ✅ Gradient background
- ✅ Shadow for depth
- ✅ White icons
- ✅ Rounded corners

### Suggestion Chips

**Style:** Gradient with shadow

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF7B2CBF), // Deep Purple
        Color(0xFF06B6D4), // Cyan
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF7B2CBF).withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Text(
    label,
    style: const TextStyle(
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

**Features:**
- ✅ Gradient background
- ✅ Subtle shadow
- ✅ White text
- ✅ Rounded corners

### Welcome Screen

**Style:** Soft background with gradient text

```dart
Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF8FAFC), // Soft White
        Color(0xFFFFFFFF), // White
      ],
    ),
  ),
  child: Center(
    child: Column(
      children: [
        // Logo
        Image.asset('assets/logo.png', width: 120, height: 120),
        
        // Gradient text
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF7B2CBF),
              Color(0xFF06B6D4),
            ],
          ).createShader(bounds),
          child: const Text(
            'Welcome to Librio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  ),
)
```

**Features:**
- ✅ Soft background gradient
- ✅ Gradient text (ShaderMask)
- ✅ Professional appearance
- ✅ Clear hierarchy

### Logo

**Style:** Official logo with fallback

```dart
Image.asset(
  'assets/logo.png',
  height: 32,
  errorBuilder: (context, error, stackTrace) {
    // Fallback: Gradient circle with "L"
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7B2CBF),
            Color(0xFF06B6D4),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'L',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  },
)
```

**Features:**
- ✅ Official logo displayed
- ✅ Gradient fallback
- ✅ Consistent sizing
- ✅ Professional appearance

---

## 🎯 Design Principles

### Color Usage

1. **AppBar:** Full gradient (left → right)
2. **Buttons:** Gradient (top-left → bottom-right)
3. **Chips:** Gradient (left → right)
4. **Text:** White on gradient, gradient text with ShaderMask
5. **Shadows:** Purple-based with opacity

### Typography

- **Title:** 20-24px, Bold, White on gradient
- **Body:** 14-16px, Regular, Dark on light
- **Buttons:** 14px, Medium weight, White

### Spacing

- **Padding:** 16px standard
- **Margin:** 12-24px between sections
- **Icon size:** 20-32px

### Shadows

- **Blur radius:** 8-12px
- **Offset:** (0, 2-4)
- **Color:** Purple-based with 0.2-0.4 opacity

---

## 📐 Gradient Directions

### Horizontal (AppBar, Buttons, Chips)
```dart
begin: Alignment.centerLeft,
end: Alignment.centerRight,
```

### Diagonal (Buttons, Logo Fallback)
```dart
begin: Alignment.topLeft,
end: Alignment.bottomRight,
```

### Vertical (Welcome Screen)
```dart
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
```

---

## 🎨 Color Constants

Add to `lib/constants/colors.dart`:

```dart
class LibrioColors {
  // Primary Gradient
  static const Color deepPurple = Color(0xFF7B2CBF);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color brightBlue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF06B6D4);
  
  // Supporting
  static const Color softWhite = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color deepNavy = Color(0xFF1E293B);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [deepPurple, indigo, brightBlue, cyan],
    stops: [0.0, 0.33, 0.66, 1.0],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [deepPurple, cyan],
  );
}
```

---

## 🔄 Implementation Checklist

- ✅ AppBar with gradient
- ✅ Buttons with gradient
- ✅ Chips with gradient
- ✅ Welcome screen with gradient
- ✅ Logo with fallback
- ✅ Shadow effects
- ✅ White text on gradient
- ✅ Gradient text (ShaderMask)
- ✅ Consistent spacing
- ✅ Professional appearance

---

## 📱 Responsive Design

The gradient theme works well on all screen sizes:

- **Mobile:** Full gradient visible, buttons sized appropriately
- **Tablet:** Gradient scales nicely, spacing adjusts
- **Desktop:** Gradient fills available space

---

## 🎊 Visual Hierarchy

1. **AppBar:** Most prominent (full gradient)
2. **Buttons:** Secondary (gradient with shadow)
3. **Chips:** Tertiary (gradient, smaller)
4. **Text:** Supporting (white or dark)
5. **Background:** Subtle (soft white)

---

## 🚀 Future Enhancements

- [ ] Dark mode variant
- [ ] Animated gradients
- [ ] Custom gradient angles
- [ ] Accessibility improvements
- [ ] Additional color schemes

---

## 📚 References

- **Design System:** Modern gradient design
- **Color Theory:** Complementary gradients
- **Accessibility:** WCAG AA contrast ratios
- **Flutter:** Material Design 3 compatible

---

Generated: 2026-08-22  
Status: UI Theme Complete - Official Branding ✅

**The Librio app now features the official gradient color scheme with professional styling!** 🎨
