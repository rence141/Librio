# Librio Public Assets Guide

**Date**: August 23, 2026  
**Status**: ✅ Complete

---

## Overview

The `public/` folder contains all static assets for the Librio web application, including logos, icons, and manifest files.

---

## Directory Structure

```
public/
├── images/
│   ├── logo.svg              (Main logo - 512x512)
│   ├── favicon.svg           (Favicon - 64x64)
│   ├── screenshot-1.png      (Mobile screenshot - 540x720)
│   └── screenshot-2.png      (Desktop screenshot - 1280x720)
├── icons/
│   ├── icon-192.svg          (PWA icon - 192x192)
│   ├── icon-512.svg          (PWA icon - 512x512)
│   └── icon-maskable.svg     (Adaptive icon)
└── manifest.json             (PWA manifest)
```

---

## Assets Description

### Logo Assets

#### `images/logo.svg`
- **Size**: 512x512 (scalable)
- **Format**: SVG (vector)
- **Usage**: Landing page, admin dashboard, branding
- **Colors**: Purple → Blue → Cyan gradient
- **Features**: Stylized "L" with accent elements

#### `images/favicon.svg`
- **Size**: 64x64 (scalable)
- **Format**: SVG (vector)
- **Usage**: Browser tab icon
- **Colors**: Purple → Blue gradient
- **Features**: Simplified "L" design

### Icon Assets

#### `icons/icon-192.svg`
- **Size**: 192x192 (scalable)
- **Format**: SVG (vector)
- **Usage**: PWA home screen icon (mobile)
- **Purpose**: Standard and maskable

#### `icons/icon-512.svg`
- **Size**: 512x512 (scalable)
- **Format**: SVG (vector)
- **Usage**: PWA splash screen, app store
- **Purpose**: Standard and maskable

### Configuration Files

#### `manifest.json`
- **Purpose**: Progressive Web App manifest
- **Features**:
  - App name and description
  - Icon definitions
  - Theme colors
  - Display mode
  - Categories
  - Screenshots

---

## Color Palette

```
Primary:     #3B82F6 (Blue)
Secondary:   #8B5CF6 (Purple)
Accent:      #10B981 (Green)
Tertiary:    #06B6D4 (Cyan)
Background:  #FFFFFF (White)
```

---

## Usage Examples

### In Next.js Components

```tsx
// Logo in header
import Image from 'next/image';

export default function Header() {
  return (
    <div className="flex items-center gap-2">
      <Image
        src="/images/logo.svg"
        alt="Librio Logo"
        width={40}
        height={40}
      />
      <h1>Librio</h1>
    </div>
  );
}
```

### In HTML

```html
<!-- Favicon -->
<link rel="icon" href="/images/favicon.svg" type="image/svg+xml" />

<!-- Apple Web App -->
<link rel="apple-touch-icon" href="/images/logo.svg" />

<!-- PWA Manifest -->
<link rel="manifest" href="/manifest.json" />
```

### In CSS

```css
/* Background image -->
.hero {
  background-image: url('/images/logo.svg');
  background-size: contain;
  background-repeat: no-repeat;
}
```

---

## Adding New Assets

### Adding a Logo Variant

1. Create SVG file in `public/images/`
2. Name it descriptively (e.g., `logo-dark.svg`)
3. Use consistent color palette
4. Test at multiple sizes
5. Update this guide

### Adding Screenshots

1. Create screenshots (540x720 for mobile, 1280x720 for desktop)
2. Save as PNG in `public/images/`
3. Name them `screenshot-1.png`, `screenshot-2.png`, etc.
4. Update `manifest.json`

### Adding Icons

1. Create icon in `public/icons/`
2. Use SVG format for scalability
3. Ensure safe zone for adaptive icons
4. Update `manifest.json` if needed

---

## Best Practices

### SVG Optimization
- Remove unnecessary attributes
- Use meaningful IDs
- Optimize gradients
- Minimize file size
- Test rendering at small sizes

### Responsive Images
- Use SVG for logos and icons (scalable)
- Use PNG for screenshots (raster)
- Provide multiple sizes where needed
- Use `next/image` for optimization

### Accessibility
- Add `alt` text to all images
- Use semantic HTML
- Ensure sufficient contrast
- Test with screen readers

### Performance
- Optimize SVG files
- Use appropriate formats
- Lazy load where possible
- Cache static assets

---

## PWA Configuration

### Manifest Features
- App name and description
- Icons for home screen
- Theme colors
- Display mode (standalone)
- Orientation (portrait)
- Categories (education, productivity)
- Screenshots for app stores

### Installation
Users can install as PWA on:
- Android devices
- iOS devices (iOS 16.4+)
- Windows
- macOS
- Linux

### Theme Colors
- **Theme Color**: #3B82F6 (shown in browser UI)
- **Background Color**: #FFFFFF (splash screen)

---

## Updating Assets

### Logo Update Process

1. **Create new logo** (SVG format)
2. **Save to** `public/images/logo.svg`
3. **Update favicon** `public/images/favicon.svg`
4. **Update icons** `public/icons/icon-*.svg`
5. **Test rendering** at all sizes
6. **Update manifest** if needed
7. **Clear browser cache** for testing
8. **Commit changes** to git

### Verification Checklist

- [ ] Logo displays correctly at 32x32
- [ ] Logo displays correctly at 64x64
- [ ] Logo displays correctly at 192x192
- [ ] Logo displays correctly at 512x512
- [ ] Favicon shows in browser tab
- [ ] PWA icon shows on home screen
- [ ] Colors match brand guidelines
- [ ] SVG files are optimized
- [ ] No rendering artifacts
- [ ] Accessibility standards met

---

## Troubleshooting

### Logo Not Displaying
- Check file path (case-sensitive on Linux)
- Verify SVG syntax
- Check browser console for errors
- Clear browser cache

### Favicon Not Showing
- Use SVG or ICO format
- Clear browser cache
- Hard refresh (Ctrl+Shift+R)
- Check manifest.json

### PWA Icon Not Showing
- Verify icon sizes in manifest
- Check icon file paths
- Ensure SVG is valid
- Test on actual device

### Color Issues
- Verify color codes
- Check gradient definitions
- Test in different browsers
- Ensure sufficient contrast

---

## Resources

### Design Tools
- [Figma](https://figma.com) - Design and export SVG
- [Adobe XD](https://www.adobe.com/products/xd.html) - Design
- [Inkscape](https://inkscape.org) - Free SVG editor

### Optimization Tools
- [SVGO](https://github.com/svg/svgo) - SVG optimizer
- [TinyPNG](https://tinypng.com) - Image compression
- [ImageOptim](https://imageoptim.com) - Image optimization

### Documentation
- [MDN: Web App Manifest](https://developer.mozilla.org/en-US/docs/Web/Manifest)
- [Web.dev: PWA](https://web.dev/progressive-web-apps/)
- [SVG Spec](https://www.w3.org/TR/SVG2/)

---

## Next Steps

1. **Review assets** in `public/` folder
2. **Test on different devices** (mobile, tablet, desktop)
3. **Verify PWA installation** works
4. **Update with official logo** when available
5. **Add screenshots** for app stores
6. **Monitor performance** metrics

---

## Support

For asset-related questions, contact: design@librio.com

---

*Generated: August 23, 2026*  
*Status: Complete*
