# SpendSmart - SwiftUI View Architecture

> A detailed guide to the SwiftUI implementation in SpendSmart, covering view hierarchy, components, patterns, and best practices

## 📖 Table of Contents

1. [SwiftUI Overview](#swiftui-overview)
2. [View Hierarchy](#view-hierarchy)
3. [Property Wrappers](#property-wrappers)
4. [Navigation Patterns](#navigation-patterns)
5. [Custom Views & Components](#custom-views--components)
6. [Styling & Theming](#styling--theming)
7. [Common Patterns](#common-patterns)
8. [Best Practices](#best-practices)

---

## SwiftUI Overview

SwiftUI is Apple's declarative UI framework for building user interfaces. In SpendSmart, SwiftUI is used for **all user-facing views**, with UIKit only used for camera/gallery integration.

### Key Characteristics

- **Declarative:** Describe WHAT to show, not HOW
- **Reactive:** Views automatically update when data changes
- **Composable:** Build complex UIs from simple views
- **Type-Safe:** Compile-time checks for UI correctness

### Why SwiftUI?

✅ **Faster Development:** Less code, more powerful  
✅ **Live Preview:** See changes instantly in Xcode  
✅ **Automatic Updates:** UI updates when state changes  
✅ **Modern:** Apple's recommended approach for new apps  

---

## View Hierarchy

### Root View Structure

The app's view hierarchy starts from `SpendSmartApp.swift`:

```
SpendSmartApp (App Protocol)
    ↓
ContentView (Root Router)
    ├── LaunchScreen (if not logged in)
    │   ├── Feature Introduction
    │   └── Sign In / Guest Mode Options
    │
    └── TabView (if logged in)
        ├── DashboardView (Home Tab)
        │   ├── SavingsSummaryView
        │   ├── MonthlyBarChartView
        │   ├── ExpenseCategoryListView
        │   └── FAB (New Expense Button)
        │
        ├── HistoryView (History Tab)
        │   └── Receipt List
        │
        └── SettingsView (Settings Tab)
            ├── Account Settings
            ├── Currency Settings
            └── App Info
```

### Navigation Flow

**Location:** `Views/ContentView.swift`

```swift
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                // Main app content
                TabView { ... }
            } else {
                // Authentication screen
                LaunchScreen(appState: appState)
            }
        }
    }
}
```

**Decision Logic:**
1. Check `appState.isLoggedIn`
2. Show `LaunchScreen` if not logged in
3. Show `TabView` with main app if logged in

---

## Property Wrappers

SwiftUI uses **property wrappers** to manage state and data flow. Here's what each one does:

### 1. @State

**Purpose:** Local state within a view

**Use Case:** State that belongs to a single view and doesn't need to be shared

**Example:**
```swift
struct NewExpenseView: View {
    @State private var showImagePicker = false
    @State private var capturedImages: [UIImage] = []
    @State private var isLoading = false
}
```

**Characteristics:**
- View owns and manages the state
- State is private to the view
- Changing state triggers view updates

**When to Use:**
- Form input values
- UI state (show/hide sheets, loading states)
- Temporary data

---

### 2. @StateObject

**Purpose:** Creates and owns an `ObservableObject`

**Use Case:** When a view needs to create and own a view model or observable object

**Example:**
```swift
struct DashboardView: View {
    @StateObject private var currencyManager = CurrencyManager.shared
}
```

**Characteristics:**
- View creates and owns the object
- Object persists for view's lifetime
- Only one instance created

**When to Use:**
- View models
- Services that need to be observed
- Objects that should persist with the view

---

### 3. @EnvironmentObject

**Purpose:** Reads shared state from parent

**Use Case:** Accessing app-wide state that's injected from the root

**Example:**
```swift
struct DashboardView: View {
    @EnvironmentObject var appState: AppState  // Injected from root
}
```

**How it works:**
```swift
// At root level
ContentView()
    .environmentObject(appState)  // Provides to all children

// In any child view
@EnvironmentObject var appState: AppState  // Automatically receives it
```

**Characteristics:**
- No need to pass down through multiple views
- Automatically available to all descendants
- Must be provided by parent (app crashes if missing)

**When to Use:**
- App-wide state (`AppState`)
- Shared data between many views
- Avoid prop drilling

---

### 4. @Binding

**Purpose:** Two-way data binding between views

**Use Case:** When child view needs to modify parent's state

**Example:**
```swift
struct ParentView: View {
    @State private var showSheet = false
    
    var body: some View {
        ChildView(showSheet: $showSheet)  // Pass binding with $
    }
}

struct ChildView: View {
    @Binding var showSheet: Bool  // Can modify parent's state
    
    var body: some View {
        Button("Close") {
            showSheet = false  // Updates parent's state
        }
    }
}
```

**Characteristics:**
- Creates two-way connection
- Changes in child update parent
- Use `$` to pass binding

**When to Use:**
- Forms and inputs
- Child views that need to modify parent state
- Two-way data flow

---

### 5. @Published

**Purpose:** Makes properties observable (used in classes)

**Use Case:** Properties that should trigger UI updates when changed

**Example:**
```swift
class AppState: ObservableObject {
    @Published var isLoggedIn = false  // View updates when this changes
    @Published var userEmail = ""
}
```

**Characteristics:**
- Used in `ObservableObject` classes
- Automatically notifies observers
- Views update when `@Published` property changes

**When to Use:**
- Observable objects
- Properties that need to trigger view updates

---

### Property Wrapper Comparison

| Wrapper | Ownership | Scope | When to Use |
|---------|-----------|-------|-------------|
| `@State` | View owns | Single view | Local UI state |
| `@StateObject` | View creates & owns | Single view | View models, services |
| `@EnvironmentObject` | Parent provides | All descendants | App-wide state |
| `@Binding` | Shared reference | Two views | Two-way data flow |
| `@Published` | Observable object | Any observer | Reactive properties |

---

## Navigation Patterns

### 1. TabView (Main Navigation)

**Location:** `Views/ContentView.swift` (lines 29-54)

**Pattern:** Tab-based navigation for main app screens

```swift
TabView {
    DashboardView(email: appState.userEmail)
        .tabItem {
            Image(systemName: "house")
            Text("Home")
        }
    
    NavigationView {
        HistoryView()
    }
    .tabItem {
        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
        Text("History")
    }
    
    NavigationView {
        SettingsView()
    }
    .tabItem {
        Image(systemName: "gear")
        Text("Settings")
    }
}
```

**Use Case:** Main app navigation (persistent bottom tabs)

---

### 2. Sheet Presentation (Modal)

**Pattern:** Present views as modals that slide up from bottom

**Example - New Expense:**
```swift
struct DashboardView: View {
    @State private var showNewExpenseSheet = false
    
    var body: some View {
        Button("New Expense") {
            showNewExpenseSheet = true
        }
        .sheet(isPresented: $showNewExpenseSheet) {
            NewExpenseView(onReceiptAdded: { receipt in
                // Handle new receipt
            })
            .environmentObject(appState)
        }
    }
}
```

**Example - Receipt Detail:**
```swift
struct HistoryView: View {
    @State private var selectedReceipt: Receipt? = nil
    
    var body: some View {
        List(receipts) { receipt in
            Button(receipt.store_name) {
                selectedReceipt = receipt
            }
        }
        .sheet(item: $selectedReceipt) { receipt in
            ReceiptDetailView(receipt: receipt)
        }
    }
}
```

**When to Use:**
- Modal content (full-screen or partial)
- Temporary views (forms, details)
- Content that should be dismissed

---

### 3. NavigationView & NavigationLink

**Pattern:** Hierarchical navigation (stack-based)

**Example:**
```swift
NavigationView {
    List(receipts) { receipt in
        NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
            ReceiptRow(receipt: receipt)
        }
    }
    .navigationTitle("History")
}
```

**When to Use:**
- Drill-down navigation
- Detail views from lists
- Stack-based navigation

**Note:** SpendSmart primarily uses **sheets** for detail views instead of NavigationLink.

---

### 4. Conditional Views

**Pattern:** Show different views based on state

**Example:**
```swift
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                if appState.isForceUpdateRequired {
                    ForcedUpdateBlockingView()
                } else if appState.isFirstLogin && !appState.isOnboardingComplete {
                    OnboardingView()
                } else {
                    TabView { ... }
                }
            } else {
                LaunchScreen(appState: appState)
            }
        }
    }
}
```

**Use Case:**
- Authentication flow
- Onboarding
- Feature flags
- Loading states

---

## Custom Views & Components

### Reusable Components Location

**Folder:** `Views/HelperViews/`

The app uses many reusable components:

| Component | Purpose |
|-----------|---------|
| `ItemCardView.swift` | Display individual receipt items |
| `ReceiptDetailView.swift` | Full receipt details screen |
| `BackgroundGradientView.swift` | Reusable gradient backgrounds |
| `CustomAsyncImage.swift` | Async image loading with placeholder |
| `EmptyStateView.swift` | Empty state UI (no receipts, etc.) |
| `ToastView.swift` | Toast notifications |
| `MapViewModal.swift` | Map view with receipts |
| `VersionUpdateAlert.swift` | Version update alerts |

---

### Component Examples

#### 1. BackgroundGradientView

**Purpose:** Consistent gradient backgrounds across views

**Usage:**
```swift
ZStack {
    BackgroundGradientView()
    
    // Your content here
    VStack { ... }
}
```

---

#### 2. ItemCardView

**Purpose:** Display receipt items with styling

**Location:** `Views/HelperViews/ItemCardView.swift`

**Features:**
- Category badges
- Price display with currency conversion
- Discount indicators
- Color-coded categories

**Usage:**
```swift
ForEach(receipt.items) { item in
    ReceiptItemCard(
        item: item,
        logoColors: colors,
        index: index,
        currencyCode: receipt.currency
    )
}
```

---

#### 3. CustomAsyncImage

**Purpose:** Load images asynchronously with placeholder

**Usage:**
```swift
CustomAsyncImage(urlString: receipt.image_urls.first ?? "")
    .aspectRatio(contentMode: .fit)
    .cornerRadius(12)
```

**Benefits:**
- Handles loading states
- Shows placeholder while loading
- Caches images
- Handles errors gracefully

---

## View File Structure

### Typical View Structure

```swift
struct MyView: View {
    // MARK: - Properties
    @EnvironmentObject var appState: AppState
    @State private var localState = false
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack {
            // View content
        }
        .onAppear {
            // Initialization
        }
    }
    
    // MARK: - Helper Methods
    func helperMethod() {
        // Helper code
    }
}

// MARK: - Preview
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
            .environmentObject(AppState())
    }
}
```
---

## Common Patterns

For detailed information about common SwiftUI patterns used in SpendSmart, see:

👉 **[Common Patterns Guide](view/common_patterns.md)** - Complete guide to async data loading, refreshable lists, empty states, progress indicators, charts, and more

---

## Best Practices

### 1. View Composition

**Break down large views into smaller components:**

```swift
// ✅ Good: Composed view
struct DashboardView: View {
    var body: some View {
        VStack {
            HeaderView()
            SummaryCardView()
            ChartsView()
            CategoryListView()
        }
    }
}

// ❌ Bad: One huge view with everything
```

---

### 2. Extract Reusable Components

**Create reusable views for repeated UI:**

```swift
// Create once, use many times
struct ReceiptCard: View {
    let receipt: Receipt
    
    var body: some View {
        // Card UI
    }
}

// Use everywhere
ForEach(receipts) { receipt in
    ReceiptCard(receipt: receipt)
}
```

---

### 3. Use Computed Properties

**Calculate values in computed properties:**

```swift
struct DashboardView: View {
    @State private var receipts: [Receipt] = []
    
    var totalExpense: Double {
        receipts.reduce(0) { $0 + $1.total_amount }
    }
    
    var body: some View {
        Text("Total: $\(totalExpense)")
    }
}
```

---

### 4. Environment Values

**Access system values via `@Environment`:**

```swift
@Environment(\.colorScheme) private var colorScheme
@Environment(\.dismiss) private var dismiss

// Use
if colorScheme == .dark { ... }
dismiss()  // Dismiss current sheet
```

---

### 5. Animation

**Use animations for smooth transitions:**

```swift
// Animate state changes
withAnimation {
    receipts = newReceipts
}

// Animate specific properties
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.spring(), value: isPressed)
```

---

### 6. Performance Optimization

**Use `id` for List performance:**

```swift
List(receipts, id: \.id) { receipt in
    // View
}
```

**Lazy loading for large lists:**

```swift
LazyVStack {
    ForEach(receipts) { receipt in
        ReceiptCard(receipt: receipt)
    }
}
```

---

### 7. Error Handling in Views

**Show user-friendly errors:**

```swift
@State private var errorMessage: String?

var body: some View {
    VStack {
        // Content
    }
    .alert("Error", isPresented: .constant(errorMessage != nil)) {
        Button("OK") { errorMessage = nil }
    } message: {
        Text(errorMessage ?? "")
    }
}
```

---

## Common SwiftUI Patterns in SpendSmart

### Pattern 1: State-Driven UI

```swift
struct MyView: View {
    @State private var isLoading = false
    @State private var data: [Item] = []
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if data.isEmpty {
                EmptyStateView()
            } else {
                List(data) { item in
                    ItemRow(item: item)
                }
            }
        }
    }
}
```

**Used in:** `DashboardView`, `HistoryView`, `NewExpenseView`

---

### Pattern 2: Sheet Presentation

```swift
struct ParentView: View {
    @State private var showSheet = false
    @State private var selectedItem: Item? = nil
    
    var body: some View {
        Button("Show") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            ChildView()
        }
        .sheet(item: $selectedItem) { item in
            DetailView(item: item)
        }
    }
}
```

**Used in:** `DashboardView` → `NewExpenseView`, `HistoryView` → `ReceiptDetailView`

---

### Pattern 3: Environment Object Injection

```swift
// Root level
ContentView()
    .environmentObject(appState)

// Deep in hierarchy
struct DeepChildView: View {
    @EnvironmentObject var appState: AppState  // Automatically available
}
```

**Used throughout:** All views that need `AppState`

---

### Pattern 4: Async Data Fetching

```swift
struct DataView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        List(items) { ... }
            .onAppear {
                Task {
                    items = await fetchItems()
                }
            }
    }
}
```

**Used in:** `DashboardView`, `HistoryView`

---

## SwiftUI vs UIKit

### When SwiftUI is Used

✅ **All user interfaces**
✅ **Navigation**
✅ **Lists and collections**
✅ **Forms**
✅ **Charts**

### When UIKit is Used

⚠️ **Camera interface** (`UIImagePickerController`)
⚠️ **Photo picker** (`PHPickerViewController`)
⚠️ **Image handling** (`UIImage`, `UIImageView`)
⚠️ **Custom UI controls** (via `UIViewControllerRepresentable`)

### Bridging UIKit to SwiftUI

**Pattern:** `UIViewControllerRepresentable`

```swift
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        return PHPickerViewController(configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Handle image selection
        }
    }
}
```

**Usage:**
```swift
struct MyView: View {
    @State private var image: UIImage?
    
    var body: some View {
        ImagePicker(image: $image)
    }
}
```

---

## Next Steps

- Explore individual view files to see patterns in action
- Check out `DashboardView.swift` for complex UI examples
- Review `NewExpenseView.swift` for async patterns
- See `HelperViews/` for reusable components
- See **[Style Guide](ui/style.md)** for detailed information about styling patterns, olors, fonts, reusable UI components, fonts, colors, and theming

---

*For more SwiftUI resources, see:*
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Apple's SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

