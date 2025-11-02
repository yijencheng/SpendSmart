# SpendSmart - Services Architecture

> A detailed guide to the Services layer in SpendSmart, covering business logic, external operations, and service patterns

## 📖 Table of Contents

1. [Services Overview](#services-overview)
2. [Singleton Pattern](#singleton-pattern)
3. [Key Services](#key-services)
4. [Service Responsibilities](#service-responsibilities)
5. [Service Usage Patterns](#service-usage-patterns)
6. [Error Handling](#error-handling)
7. [Next Steps](#next-steps)

---

## Services Overview

Services contain all **business logic** and **external operations** in SpendSmart. They act as a bridge between Views (UI) and external systems (APIs, storage, etc.).

### Key Characteristics

- **Separation of Concerns:** Business logic separated from UI code
- **Singleton Pattern:** One shared instance per service
- **Testable:** Services can be easily mocked for testing
- **Reusable:** Same service used across multiple views

### Why Services?

✅ **Clean Architecture:** Views focus on UI, Services handle logic  
✅ **Testability:** Mock services for unit tests  
✅ **Maintainability:** Changes in one place affect all views  
✅ **Swappable:** Easy to swap implementations (e.g., mock for testing)

---

## Singleton Pattern

All services use the **Singleton pattern** to ensure only one instance exists.

### Implementation

```swift
class BackendAPIService {
    static let shared = BackendAPIService()
    
    private init() {
        // Initialize service
    }
}
```

### Usage

```swift
// Access service anywhere in the app
BackendAPIService.shared.makeRequest(...)
LocalStorageService.shared.saveReceipts(...)
AIService.shared.generateContent(...)
```

**Key Concept:** `static let shared` creates one shared instance accessible throughout the app.

---

## Key Services

### 1. BackendAPIService

**Purpose:** Communicates with backend server

**Key Responsibilities:**
- Authentication (sign in, sign out)
- Receipt CRUD operations
- AI content generation
- Image uploads

**Location:** `Services/BackendAPIService.swift`

### 2. LocalStorageService

**Purpose:** Stores data locally (for guest mode)

**Key Responsibilities:**
- Save/retrieve receipts from UserDefaults
- Manage local data persistence
- Guest mode data storage

**Location:** `Services/LocalStorageService.swift`

### 3. AIService

**Purpose:** Handles AI-powered receipt parsing

**Key Responsibilities:**
- Receipt data extraction from images
- AI content generation
- Receipt validation

**Location:** `Services/GeminiAPIService.swift`

### 4. CurrencyManager

**Purpose:** Currency conversion and formatting

**Key Responsibilities:**
- Currency conversion using exchange rates
- Amount formatting with currency symbols
- Preferred currency management

**Location:** `Services/CurrencyManager.swift`

### 5. ImageStorageService

**Purpose:** Manages receipt image uploads

**Key Responsibilities:**
- Upload images to cloud storage
- Fallback to local storage
- Image URL management

**Location:** `Services/ImageStorageService.swift`

---

## Service Responsibilities

### Separation of Concerns

**Views:** Handle user interactions and display data

**Services:** Handle business logic and external operations

**Models:** Represent data structures

### Example: Adding a Receipt

```swift
// View layer
struct NewExpenseView: View {
    func processReceipt(image: UIImage) {
        Task {
            // Service handles business logic
            let receipt = try await AIService.shared.parseReceipt(from: image)
            
            // Service handles storage
            if appState.useLocalStorage {
                LocalStorageService.shared.addReceipt(receipt)
            } else {
                try await BackendAPIService.shared.createReceipt(receipt)
            }
        }
    }
}
```

**Key Concept:** Views don't contain business logic - they delegate to services.

---

## Service Usage Patterns

### Async/Await Pattern

All network and async operations use `async/await`:

```swift
func fetchReceipts() async throws -> [Receipt] {
    let response = try await BackendAPIService.shared.getReceipts()
    return response.receipts
}
```

### Error Handling

Services throw errors that views can catch:

```swift
do {
    let receipt = try await AIService.shared.parseReceipt(from: image)
} catch {
    // Handle error
    print("Error: \(error)")
}
```

### Observable Services

Some services use `ObservableObject` for reactive updates:

```swift
class CurrencyManager: ObservableObject {
    @Published var preferredCurrency: String
    @Published var isLoading: Bool
}
```

---

## Error Handling

Services handle errors and propagate them to views:

### Error Types

```swift
enum BackendAPIError: Error {
    case unauthorized
    case rateLimited
    case serverError(String)
    case networkError(Error)
}
```

### Error Propagation

```swift
func makeRequest(...) async throws -> Response {
    // Service catches network errors
    do {
        let response = try await session.data(for: request)
        return response
    } catch {
        throw BackendAPIError.networkError(error)
    }
}
```

**Key Concept:** Services catch low-level errors and convert them to domain-specific errors.

---

## Next Steps

- Explore individual service files to see implementations
- Check out `BackendAPIService.swift` for API communication patterns
- Review `LocalStorageService.swift` for local data management
- See service methods in action by tracing through `NewExpenseView.swift`

### Related Documentation

- **[Data Models](models.md)** - Deep dive into data structures, Codable, and model relationships
- **[API Documentation](api.md)** - Complete API endpoint reference and usage
- **[Storage Guide](storage.md)** - Detailed storage strategies and alternatives

### Next: Deep Dive into Data Models

Now that you understand how services work, learn about the data models they use:

👉 **[Data Models Guide](models.md)** - Detailed walkthrough of data structures, Codable implementation, and model relationships

---

*For more iOS development resources, see:*
- [Swift Documentation](https://docs.swift.org/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

