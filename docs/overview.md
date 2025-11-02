# SpendSmart - Project Overview

> A high-level walkthrough for understanding the SpendSmart iOS app architecture and structure

## 📖 Table of Contents

1. [What is SpendSmart?](#what-is-spendsmart)
2. [Architecture Overview](#architecture-overview)
3. [Project Structure](#project-structure)
4. [Key Components](#key-components)
5. [Data Flow](#data-flow)
6. [iOS Concepts for Beginners](#ios-concepts-for-beginners)
7. [Getting Started](#getting-started)

---

## What is SpendSmart?

SpendSmart is an iOS expense tracking app that uses AI to automatically extract information from receipt photos. Users can:

- 📸 **Capture receipts** using their iPhone camera
- 🤖 **AI-powered extraction** of store details, items, prices, and totals
- 💾 **Store and organize** receipts locally or in the cloud
- 📊 **View insights** with charts and spending analytics
- 🌍 **Multi-currency support** with automatic conversion

---

## Architecture Overview

SpendSmart follows a **Model-View-Controller (MVC)** architecture with a **Services Layer**, commonly used in iOS development.

```
┌─────────────────────────────────────────────────┐
│                  App Entry Point                 │
│              (SpendSmartApp.swift)               │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              State Management                    │
│               (AppState.swift)                   │
│    • Login status • User info • App state       │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌──────────────┐           ┌──────────────┐
│   Views      │           │   Services   │
│ (SwiftUI)    │◄─────────►│ (Business    │
│              │           │  Logic)     │
└──────────────┘           └──────────────┘
        │                           │
        │                           ▼
        │                  ┌──────────────┐
        │                  │   Models     │
        │                  │ (Data Struct)│
        └──────────────────►└──────────────┘
```

### Architecture Principles

1. **Separation of Concerns**: Views handle UI, Services handle business logic, Models handle data
2. **Single Source of Truth**: `AppState` manages all app-wide state
3. **Reactive UI**: Views automatically update when state changes
4. **Service Layer**: All external operations (API calls, storage) go through services

---

## Project Structure

```
SpendSmart/
│
├── SpendSmartApp.swift          # 🚀 App entry point & lifecycle
│
├── Models/                       # 📦 Data structures
│   ├── AppState.swift            #   Central state management
│   ├── Receipt.swift             #   Receipt data model
│   └── ...
│
├── Views/                        # 🎨 User interface
│   ├── ContentView.swift         #   Root view (navigation logic)
│   ├── DashboardView.swift       #   Home screen with charts
│   ├── HistoryView.swift         #   Receipt list view
│   ├── NewExpenseView.swift      #   Receipt capture & processing
│   ├── SettingsView.swift        #   App settings
│   └── HelperViews/              #   Reusable UI components
│       ├── ReceiptDetailView.swift
│       ├── MapViewModal.swift
│       └── ...
│
├── Services/                     # 🔧 Business logic
│   ├── BackendAPIService.swift   #   Backend API communication
│   ├── LocalStorageService.swift #   Local data storage
│   ├── CurrencyManager.swift     #   Currency conversion
│   ├── AIService.swift           #   AI/OCR processing
│   └── ...
│
├── Extensions/                   # 🔌 Model extensions
│   └── Receipt+BackendAPI.swift  #   API serialization
│
└── Utils/                        # 🛠 Helper utilities
    └── Extensions.swift          #   Utility extensions
```

---

## Key Components

### 1. App Entry Point (`SpendSmartApp.swift`)

The starting point of the app. Similar to `main()` in other languages.

**Key Responsibilities:**
- Initialize the app
- Create and provide `AppState` to all views
- Handle app lifecycle events (background/foreground)
- Check for app updates

**Key Concept:** `@main` marks this as the entry point. `@StateObject` creates app-wide state that lives for the app's lifetime.

---

### 2. Views (SwiftUI)

Views define what the user sees and handle user interactions.

**Navigation Flow:**
```
ContentView (Root)
├── LaunchScreen (Login/Auth)
└── TabView (Main App)
    ├── DashboardView (Home)
    ├── HistoryView (Receipts List)
    └── SettingsView (Settings)
```

**Key Views:**
- **`ContentView`**: Root view that decides which screen to show
- **`DashboardView`**: Main screen with spending charts and summary
- **`NewExpenseView`**: Receipt capture and AI processing
- **`HistoryView`**: List of all receipts

**Key Concept:** Views are declarative (you describe WHAT to show, not HOW to show it). SwiftUI handles the rendering automatically.

---
### 3. State Management (`AppState.swift`)

The "brain" of the app. Stores all app-wide state that multiple views need.

**Key Properties:**
- `isLoggedIn`: Whether user is authenticated
- `userEmail`: Current user's email
- `isGuestUser`: Whether user is in guest mode
- `useLocalStorage`: Whether to use local storage vs cloud

**Key Concept:** `ObservableObject` + `@Published` makes this reactive. When properties change, all views using `@EnvironmentObject` automatically update.

**Pattern:** Single Source of Truth - one place for all shared state.

---

### 4. Services Layer

Services contain all business logic and external operations. They follow the **Singleton pattern** (one shared instance).

**Key Services:**

| Service | Purpose |
|---------|---------|
| `BackendAPIService` | Communicates with backend server for authentication, data sync |
| `LocalStorageService` | Stores receipts locally (for guest mode) |
| `AIService` | Handles AI-powered receipt parsing |
| `CurrencyManager` | Currency conversion and formatting |
| `ImageStorageService` | Manages receipt image uploads |

**Pattern:** Singleton - `static let shared = ServiceName()` ensures only one instance exists.

**Why Services?**
- Separates business logic from UI
- Makes code testable
- Allows easy swapping of implementations (e.g., mock services for testing)

---

### 5. Models

Data structures that represent real-world entities.

**Key Models:**
- **`Receipt`**: Represents a receipt with store info, items, totals
- **`ReceiptItem`**: Individual item on a receipt
- **`AppState`**: App-wide state (also acts as a ViewModel)

**Key Concept:** Models conform to `Codable` for easy conversion to/from JSON when communicating with APIs.

---

## Data Flow

### Example: Adding a New Receipt

```
1. User Action
   ↓
   User taps "New Expense" button in DashboardView
   
2. View Layer
   ↓
   DashboardView shows NewExpenseView as a sheet
   
3. User Captures Receipt
   ↓
   User takes photo(s) of receipt in NewExpenseView
   
4. Service Call
   ↓
   NewExpenseView calls: AIService.shared.parseReceipt(image)
   
5. AI Processing
   ↓
   AIService → BackendAPIService → Backend Server
   ↓
   Backend uses AI to extract receipt data
   ↓
   Returns structured receipt data
   
6. Model Creation
   ↓
   NewExpenseView creates Receipt model from AI response
   
7. Data Storage
   ↓
   DashboardView calls insertReceipt()
   ↓
   Checks appState.useLocalStorage:
   • Guest mode → LocalStorageService.shared.addReceipt()
   • Logged in → BackendAPIService.shared.createReceipt()
   
8. UI Update
   ↓
   AppState updates → Views automatically refresh
   ↓
   DashboardView shows new receipt in charts
```

**Key Concept:** Data flows in one direction: User → View → Service → Model → State → View Update

---

## Next: Deep Dive into SwiftUI

Now that you understand the overall architecture, learn how the SwiftUI views are structured and implemented:

👉 **[View Architecture & SwiftUI Guide](view.md)** - Detailed walkthrough of SwiftUI components, patterns, and UI implementation

The view guide covers:
- SwiftUI view hierarchy and navigation
- Property wrappers (`@State`, `@Binding`, `@EnvironmentObject`)
- Custom views and reusable components
- Styling and theming
- Common SwiftUI patterns used in SpendSmart

---