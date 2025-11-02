# Property Wrappers

A detailed guide to SwiftUI property wrappers used in SpendSmart for managing state and data flow.

---

SwiftUI uses **property wrappers** to manage state and data flow. Here's what each one does:

## 1. @State

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

## 2. @StateObject

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

## 3. @EnvironmentObject

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

## 4. @Binding

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

## 5. @Published

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

## Property Wrapper Comparison

| Wrapper | Ownership | Scope | When to Use |
|---------|-----------|-------|-------------|
| `@State` | View owns | Single view | Local UI state |
| `@StateObject` | View creates & owns | Single view | View models, services |
| `@EnvironmentObject` | Parent provides | All descendants | App-wide state |
| `@Binding` | Shared reference | Two views | Two-way data flow |
| `@Published` | Observable object | Any observer | Reactive properties |

