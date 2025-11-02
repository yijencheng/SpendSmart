# Common SwiftUI Patterns

A guide to common SwiftUI patterns used in SpendSmart.

---

## 1. Async Data Loading

**Pattern:** Load data in `Task` blocks

```swift
struct DashboardView: View {
    @State private var receipts: [Receipt] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading...")
            } else {
                ForEach(receipts) { receipt in
                    ReceiptCard(receipt: receipt)
                }
            }
        }
        .onAppear {
            Task {
                await fetchReceipts()
            }
        }
    }
    
    func fetchReceipts() async {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch data...
    }
}
```

**Key Points:**
- Use `Task { }` for async operations in views
- Update state on `MainActor` if needed
- Show loading indicators during async operations

---

## 2. Refreshable Lists

**Pattern:** Pull-to-refresh functionality

```swift
ScrollView {
    // Content
}
.refreshable {
    await fetchReceipts()
}
```

**Usage:** User can pull down to refresh data

---

## 3. Empty States

**Pattern:** Show helpful message when no data

```swift
if receipts.isEmpty {
    EmptyStateView(
        icon: "receipt",
        title: "No Receipts",
        message: "Start by adding your first receipt"
    )
} else {
    List(receipts) { ... }
}
```

**Component:** `Views/HelperViews/EmptyStateView.swift`

---

## 4. Conditional Rendering

**Pattern:** Show different UI based on conditions

```swift
var body: some View {
    Group {
        if isLoading {
            ProgressView()
        } else if receipts.isEmpty {
            EmptyStateView(...)
        } else {
            List(receipts) { ... }
        }
    }
}
```

---

## 5. Progress Indicators

**Pattern:** Show progress during async operations

**Example from NewExpenseView:**
```swift
if isAddingExpense, let step = progressStep {
    ZStack {
        // Progress circle
        Circle()
            .trim(from: 0.0, to: progress)
            .stroke(style: StrokeStyle(...))
        
        // Status text
        VStack {
            Text(step.rawValue)
            Text(step.description)
        }
    }
}
```

**States:**
- Validating Receipt
- Analyzing Receipt
- Saving to Database
- Complete

---

## 6. Alert & Toast Notifications

**Alerts:**
```swift
.alert("Error", isPresented: $showAlert) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage)
}
```

**Toasts:**
```swift
@StateObject private var toastManager = ToastManager()

.toast(toastManager: toastManager)

// Show toast
toastManager.show(
    message: "Receipt saved!",
    type: .success
)
```

---

## 7. Image Carousels

**Pattern:** Swipeable image carousel for multiple images

**Location:** `Views/NewExpenseView.swift`

```swift
TabView(selection: $currentImageIndex) {
    ForEach(0..<capturedImages.count, id: \.self) { index in
        Image(uiImage: capturedImages[index])
            .resizable()
            .scaledToFit()
    }
}
.tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
```

**Use Case:** Multiple receipt images (long receipts split across photos)

---

## 8. Charts & Data Visualization

**Framework:** Swift Charts (iOS 16+)

**Example - Monthly Bar Chart:**
```swift
Chart(monthlyData, id: \.month) { item in
    BarMark(
        x: .value("Month", item.month),
        y: .value("Amount", item.total)
    )
    .cornerRadius(6)
    .foregroundStyle(Color.blue.gradient)
}
```

**Example - Donut Chart:**
```swift
Chart(categoryData, id: \.category) { item in
    SectorMark(
        angle: .value("Total", item.total),
        innerRadius: .ratio(0.65),
        angularInset: 2.0
    )
    .cornerRadius(12)
    .foregroundStyle(by: .value("Category", item.category))
}
```

**Location:** `Views/DashboardView.swift`

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

