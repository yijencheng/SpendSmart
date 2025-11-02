# Style Guide

A simple guide to styling patterns used in SpendSmart.

---

## Custom Fonts

**Location:** `Utils/Extensions.swift`

The app uses three custom font families:

### Fonts

- **Instrument Sans** - For UI elements, buttons, labels
- **Instrument Serif** - For titles and headers
- **Space Grotesk** - For numbers and data display

### Usage

```swift
// Sans-serif (UI elements)
Text("Hello")
    .font(.instrumentSans(size: 16, weight: .medium))

// Serif (titles)
Text("SpendSmart")
    .font(.instrumentSerif(size: 28))

// Serif Italic (branding)
Text("SpendSmart")
    .font(.instrumentSerifItalic(size: 36))

// Grotesk (numbers)
Text("$123.45")
    .font(.spaceGrotesk(size: 18, weight: .bold))
```

**Font Files:**
- `Fonts/InstrumentSans-Variable.ttf`
- `Fonts/InstrumentSerif-Regular.ttf`
- `Fonts/InstrumentSerif-Italic.ttf`
- `Fonts/SpaceGrotesk-Variable.ttf`

---

## Colors

### Hex Colors

**Location:** `Utils/Extensions.swift`

Convert hex strings to SwiftUI colors:

```swift
Color(hex: "3B82F6")  // Blue
Color(hex: "6D28D9")  // Purple
Color(hex: "10B981")  // Green
```

### Dark Mode Support

Check color scheme and adapt colors:

```swift
@Environment(\.colorScheme) private var colorScheme

Text("Hello")
    .foregroundColor(colorScheme == .dark ? .white : .black)

Rectangle()
    .fill(colorScheme == .dark ? Color(hex: "282828") : Color(hex: "F0F0F0"))
```

---

## Common Styling Patterns

### Cards & Containers

**Rounded corners with shadow:**

```swift
VStack {
    // Content
}
.cornerRadius(12)
.padding()
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(colorScheme == .dark ? Color(hex: "1A1A1A") : Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
)
```

### Buttons

**Styled button pattern:**

```swift
Button("Action") {
    // Action
}
.padding(.horizontal, 20)
.padding(.vertical, 16)
.background(Color(hex: "3B82F6"))
.foregroundColor(.white)
.cornerRadius(12)
```

### Spacing

**Common padding values:**

```swift
.padding()           // 16px all sides
.padding(.horizontal) // 16px left/right
.padding(.vertical, 8) // 8px top/bottom
.padding(12)         // 12px all sides
```

---

## Background Gradients

**Location:** `Views/HelperViews/BackgroundGradientView.swift`

Animated gradient background:

```swift
BackgroundGradientView()
    .ignoresSafeArea()
```

Automatically adapts to light/dark mode with animated colors.

---

## Helper Components

### Section Headers

**Location:** `Views/HelperViews/SectionHeaderView.swift`

```swift
SectionHeaderView(
    title: "Recent",
    icon: "clock",
    color: Color(hex: "3B82F6")
)
```

Displays icon + text with consistent styling.

---

## Best Practices

1. **Use custom fonts** for consistent typography
2. **Check color scheme** for dark mode support
3. **Use consistent padding** (12, 16, 20, 24)
4. **Apply shadows** to cards/containers for depth
5. **Use cornerRadius(12)** for rounded corners
6. **Test in both** light and dark modes

---

## Quick Reference

**Card Style:**
```swift
.cornerRadius(12)
.padding()
.background(Color.white)
.shadow(radius: 5)
```

**Button Style:**
```swift
.padding(.horizontal, 20)
.padding(.vertical, 16)
.background(Color(hex: "3B82F6"))
.foregroundColor(.white)
.cornerRadius(12)
```

**Dark Mode Color:**
```swift
colorScheme == .dark ? Color(hex: "282828") : Color.white
```

