# ViewBuilder

A guide to SwiftUI's `@ViewBuilder` attribute, used to create flexible view-building closures in SpendSmart.

---

## What is ViewBuilder?

`@ViewBuilder` is a Swift attribute that allows functions and closures to accept multiple views and combine them into a single view container. It's SwiftUI's way of building views from closures.

### Key Concept

Without `@ViewBuilder`, a function that returns `some View` can only return **one view**. With `@ViewBuilder`, it can accept and combine **multiple views** into containers like `VStack`, `HStack`, or `Group`.

---

## How ViewBuilder Works

### Without ViewBuilder

```swift
// ❌ This won't compile - can't return multiple views
func makeContent() -> some View {
    Text("Hello")
    Image(systemName: "star")  // Error!
}
```

### With ViewBuilder

```swift
// ✅ This works - ViewBuilder combines multiple views
@ViewBuilder
func makeContent() -> some View {
    Text("Hello")
    Image(systemName: "star")
    Button("Tap") { }
}
// Automatically wrapped in a TupleView or Group
```

---

## Usage in SpendSmart

### Example: CustomAsyncImage

**Location:** `Views/HelperViews/CustomAsyncImage.swift`

`CustomAsyncImage` uses `@ViewBuilder` to accept custom view closures:

```swift
struct CustomAsyncImage<Content: View, Placeholder: View>: View {
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    init(
        urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
    }
}
```

**Usage:**
```swift
CustomAsyncImage(urlString: "https://example.com/image.jpg") { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 200, height: 200)
        .cornerRadius(12)
} placeholder: {
    VStack {
        ProgressView()
        Text("Loading...")
    }
}
```

**Benefits:**
- Customizable content and placeholder views
- Flexible - accepts any view type
- Clean API - no need to wrap views in containers

---

## Common Use Cases

### 1. Custom View Modifiers

```swift
struct CardModifier: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}
```

### 2. Reusable Container Views

```swift
struct SectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content()
        }
        .padding()
    }
}

// Usage
SectionContainer(title: "Settings") {
    Toggle("Enable Notifications", isOn: $notifications)
    Toggle("Enable Dark Mode", isOn: $darkMode)
}
```

### 3. Conditional View Builders

```swift
@ViewBuilder
func conditionalContent(showDetail: Bool) -> some View {
    if showDetail {
        Text("Detail View")
        Image(systemName: "info.circle")
    } else {
        Text("Summary")
    }
}
```

### 4. Dynamic View Lists

```swift
@ViewBuilder
func makeButtonList(count: Int) -> some View {
    ForEach(0..<count, id: \.self) { index in
        Button("Button \(index)") {
            // Action
        }
    }
}
```

---

## When to Use ViewBuilder

### ✅ Use @ViewBuilder When:

1. **Closure Parameters** - Functions/initializers that accept view closures
   ```swift
   init(@ViewBuilder content: () -> Content)
   ```

2. **Custom View Modifiers** - Modifiers that wrap content
   ```swift
   func body(content: Content) -> some View
   ```

3. **Helper Methods** - Methods that return complex view hierarchies
   ```swift
   @ViewBuilder func makeHeader() -> some View { ... }
   ```

4. **Generic View Builders** - Views that accept generic content
   ```swift
   struct Container<Content: View>: View {
       @ViewBuilder let content: () -> Content
   }
   ```

### ❌ Don't Use @ViewBuilder When:

1. **Simple Single Views** - If you're only returning one view
   ```swift
   // Don't need ViewBuilder
   func makeTitle() -> some View {
       Text("Title")  // Single view - no ViewBuilder needed
   }
   ```

2. **Non-View Types** - ViewBuilder only works with `View` types

3. **Computed Properties** - `body` already has implicit ViewBuilder, don't add it explicitly
   ```swift
   var body: some View {  // Implicitly @ViewBuilder
       VStack { ... }
   }
   ```

---

## ViewBuilder Limitations

### Conditional Logic

ViewBuilder supports `if-else` but not all control flow:

**✅ Supported:**
```swift
@ViewBuilder
func content(isLoading: Bool) -> some View {
    if isLoading {
        ProgressView()
    } else {
        Text("Loaded")
    }
}
```

**❌ Not Supported:**
```swift
@ViewBuilder
func content(items: [Item]) -> some View {
    switch items.count {  // Can work but limited
    case 0:
        EmptyView()
    default:
        List(items) { ... }
    }
}
```

**⚠️ Limited Support:**
```swift
@ViewBuilder
func content() -> some View {
    for item in items {  // Use ForEach instead
        Text(item.name)
    }
}
```

Use `ForEach` inside ViewBuilder for loops:
```swift
@ViewBuilder
func content() -> some View {
    ForEach(items) { item in
        Text(item.name)
    }
}
```

---

## Implicit ViewBuilder

SwiftUI automatically applies ViewBuilder to certain contexts:

### 1. View's `body` Property

```swift
struct MyView: View {
    var body: some View {  // Implicitly @ViewBuilder
        VStack {
            Text("Hello")
            Text("World")
        }
    }
}
```

### 2. Group Closures

```swift
Group {  // Implicitly @ViewBuilder
    Text("First")
    Text("Second")
}
```

### 3. Container Views

```swift
VStack {  // Implicitly @ViewBuilder
    Text("Top")
    Text("Bottom")
}
```

**You don't need to add `@ViewBuilder` in these contexts.**

---

## Advanced: ViewBuilder with Generics

### Generic View Builder Example

```swift
struct ConditionalView<TrueContent: View, FalseContent: View>: View {
    let condition: Bool
    @ViewBuilder let trueContent: () -> TrueContent
    @ViewBuilder let falseContent: () -> FalseContent
    
    var body: some View {
        if condition {
            trueContent()
        } else {
            falseContent()
        }
    }
}

// Usage
ConditionalView(condition: isLoggedIn) {
    Text("Welcome!")
    Button("Logout") { logout() }
} falseContent: {
    Text("Please login")
    Button("Login") { login() }
}
```

---

## Best Practices

### 1. Use for Flexible APIs

```swift
// ✅ Good: Flexible, accepts any view
struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack {
            content()
        }
    }
}
```

### 2. Document ViewBuilder Closures

```swift
/// A custom image view with flexible content and placeholder
/// - Parameters:
///   - url: The image URL
///   - content: ViewBuilder closure that receives the loaded Image
///   - placeholder: ViewBuilder closure for the loading state
init(
    url: URL?,
    @ViewBuilder content: @escaping (Image) -> Content,
    @ViewBuilder placeholder: @escaping () -> Placeholder
)
```

### 3. Keep ViewBuilders Simple

```swift
// ✅ Good: Simple, focused
@ViewBuilder
func makeHeader(title: String) -> some View {
    Text(title)
        .font(.headline)
    Divider()
}

// ❌ Bad: Too complex
@ViewBuilder
func makeEverything() -> some View {
    // 200 lines of view code...
}
```

---

## Summary

**ViewBuilder Key Points:**

- ✅ Combines multiple views into one
- ✅ Enables flexible closure-based view building
- ✅ Used in custom components (like `CustomAsyncImage`)
- ✅ Automatically applied to `body` and container closures
- ✅ Supports `if-else` but not all control flow

**Use ViewBuilder when:**
- Creating functions/initializers that accept view closures
- Building flexible, reusable components
- Returning complex view hierarchies from helper methods

**Don't use ViewBuilder when:**
- Returning a single view
- The context already has implicit ViewBuilder (`body`, `VStack`, etc.)

---

## Examples in SpendSmart

The best example of ViewBuilder usage in SpendSmart is `CustomAsyncImage`, which uses `@ViewBuilder` to allow flexible content and placeholder customization.

See: `Views/HelperViews/CustomAsyncImage.swift`

