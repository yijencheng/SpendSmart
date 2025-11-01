# SpendSmart - Code Examples & Usage Guide

> Practical code examples and usage patterns for the SpendSmart iOS app

## 📖 Table of Contents

1. [API Examples](#api-examples)
2. [SwiftUI Code Examples](#swiftui-code-examples)
3. [Service Usage Examples](#service-usage-examples)
4. [Common Patterns](#common-patterns)
5. [Testing Examples](#testing-examples)

---

## API Examples

### AI Content Generation Endpoint

#### Full Endpoint URL

**Production:**
```
https://spend-smart-backend-iota.vercel.app/api/ai/generate
```

**Development:**
```
http://localhost:3000/api/ai/generate
```

#### cURL Example

```bash
curl -X POST https://spend-smart-backend-iota.vercel.app/api/ai/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Extract all receipt details from this image",
    "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...",
    "systemInstruction": "You are a receipt extraction system...",
    "config": {
      "temperature": 1,
      "topP": 0.95,
      "topK": 40,
      "maxOutputTokens": 8192
    }
  }'
```

#### Swift Example

```swift
import UIKit

// Create a receipt image
let receiptImage = UIImage(named: "receipt")!

// Convert to base64
guard let imageData = receiptImage.jpegData(compressionQuality: 0.8) else {
    fatalError("Failed to convert image")
}
let base64Image = imageData.base64EncodedString()

// Prepare request
let url = URL(string: "https://spend-smart-backend-iota.vercel.app/api/ai/generate")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let body: [String: Any] = [
    "prompt": "Extract all receipt details from this image",
    "image": "data:image/jpeg;base64,\(base64Image)",
    "systemInstruction": "You are a receipt extraction system...",
    "config": [
        "temperature": 1,
        "topP": 0.95,
        "topK": 40,
        "maxOutputTokens": 8192
    ]
]

request.httpBody = try? JSONSerialization.data(withJSONObject: body)

// Make request
let (data, response) = try await URLSession.shared.data(for: request)
let result = try JSONDecoder().decode(AIContentResponse.self, from: data)
print(result.response.text)
```

#### JavaScript/TypeScript Example

```typescript
async function generateAIContent(imageFile: File) {
  // Convert image to base64
  const base64Image = await fileToBase64(imageFile);
  
  const response = await fetch('https://spend-smart-backend-iota.vercel.app/api/ai/generate', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt: 'Extract all receipt details from this image',
      image: `data:image/jpeg;base64,${base64Image}`,
      systemInstruction: 'You are a receipt extraction system...',
      config: {
        temperature: 1,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 8192
      }
    })
  });
  
  const data = await response.json();
  return data.response.text;
}

function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      const base64 = (reader.result as string).split(',')[1];
      resolve(base64);
    };
    reader.onerror = error => reject(error);
  });
}
```

#### Python Example

```python
import requests
import base64

def generate_ai_content(image_path: str):
    # Read and encode image
    with open(image_path, "rb") as image_file:
        image_data = image_file.read()
        base64_image = base64.b64encode(image_data).decode('utf-8')
    
    url = "https://spend-smart-backend-iota.vercel.app/api/ai/generate"
    
    payload = {
        "prompt": "Extract all receipt details from this image",
        "image": f"data:image/jpeg;base64,{base64_image}",
        "systemInstruction": "You are a receipt extraction system...",
        "config": {
            "temperature": 1,
            "topP": 0.95,
            "topK": 40,
            "maxOutputTokens": 8192
        }
    }
    
    response = requests.post(url, json=payload)
    return response.json()["response"]["text"]
```

---

## SwiftUI Code Examples

### Creating a New Expense View

```swift
import SwiftUI

struct MyCustomExpenseView: View {
    @EnvironmentObject var appState: AppState
    @State private var capturedImage: UIImage?
    @State private var receipt: Receipt?
    
    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                
                Button("Process Receipt") {
                    Task {
                        await processReceipt(image: image)
                    }
                }
            } else {
                Text("No image selected")
            }
        }
    }
    
    func processReceipt(image: UIImage) async {
        do {
            // Extract receipt data using AI
            let receipt = await extractReceiptFromImage(image)
            
            // Save receipt
            if appState.useLocalStorage {
                LocalStorageService.shared.addReceipt(receipt)
            } else {
                try await supabase.createReceipt(receipt)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func extractReceiptFromImage(_ image: UIImage) async -> Receipt? {
        // Use AIService to extract receipt data
        let response = try await AIService.shared.generateContent(
            prompt: "Extract receipt details...",
            image: image
        )
        
        // Parse response and create Receipt model
        // ... parsing logic
        return receipt
    }
}
```

### Using AppState for State Management

```swift
import SwiftUI

struct MyView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            if appState.isLoggedIn {
                Text("Welcome, \(appState.userEmail)")
                
                if appState.isGuestUser {
                    Text("Guest Mode")
                }
            } else {
                Text("Please log in")
            }
        }
    }
}

// In your app entry point
struct MyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MyView()
                .environmentObject(appState)
        }
    }
}
```

### Image Picker Example

```swift
import SwiftUI
import PhotosUI

struct ImagePickerExample: View {
    @State private var selectedImage: UIImage?
    @State private var showPicker = false
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            Button("Select Image") {
                showPicker = true
            }
        }
        .sheet(isPresented: $showPicker) {
            MultiImagePicker(images: Binding(
                get: { selectedImage.map { [$0] } ?? [] },
                set: { selectedImage = $0.first }
            ))
        }
    }
}
```

---

## Service Usage Examples

### Using BackendAPIService

```swift
import UIKit

// Sign in with Apple
Task {
    do {
        let response = try await BackendAPIService.shared.signInWithApple(
            idToken: appleIDToken
        )
        
        print("Signed in: \(response.data.user?.email ?? "Unknown")")
    } catch {
        print("Sign in error: \(error)")
    }
}

// Generate AI content
Task {
    do {
        let response = try await BackendAPIService.shared.generateAIContent(
            prompt: "Extract receipt details",
            image: receiptImage,
            systemInstruction: "You are a receipt parser...",
            config: [
                "temperature": 1,
                "maxOutputTokens": 8192
            ]
        )
        
        print("AI Response: \(response.response.text)")
    } catch {
        print("AI generation error: \(error)")
    }
}

// Upload image
Task {
    do {
        let response = try await BackendAPIService.shared.uploadImage(receiptImage)
        print("Image uploaded: \(response.data.url)")
    } catch {
        print("Upload error: \(error)")
    }
}
```

### Using AIService

```swift
// Generate content with AI
Task {
    do {
        let config = AIService.GenerationConfig(
            temperature: 1,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 8192,
            responseMIMEType: "application/json"
        )
        
        let response = try await AIService.shared.generateContent(
            prompt: "Extract receipt details from this image",
            image: receiptImage,
            systemInstruction: systemPrompt,
            config: config
        )
        
        // Parse the JSON response
        if let jsonString = response.text {
            let receipt = parseReceipt(from: jsonString)
            print("Extracted: \(receipt?.store_name ?? "Unknown")")
        }
    } catch {
        print("Error: \(error)")
    }
}

// Validate receipt
Task {
    do {
        let result = try await AIService.shared.validateReceipt(image: receiptImage)
        
        if result.isValid {
            print("Valid receipt! Confidence: \(result.confidence)")
        } else {
            print("Invalid receipt: \(result.message)")
        }
    } catch {
        print("Validation error: \(error)")
    }
}
```

### Using ImageStorageService

```swift
// Upload single image
Task {
    let imageURL = await ImageStorageService.shared.uploadImage(receiptImage)
    print("Image URL: \(imageURL)")
}

// Upload multiple images
Task {
    let images = [image1, image2, image3]
    let urls = await ImageStorageService.shared.uploadImages(images)
    print("Uploaded \(urls.count) images")
}
```

### Using LocalStorageService

```swift
// Save receipt locally
let receipt = Receipt(/* ... */)
LocalStorageService.shared.addReceipt(receipt)

// Get all receipts
let receipts = LocalStorageService.shared.getReceipts()
print("Found \(receipts.count) receipts")

// Update receipt
var receipts = LocalStorageService.shared.getReceipts()
if let index = receipts.firstIndex(where: { $0.id == receipt.id }) {
    receipts[index] = updatedReceipt
    LocalStorageService.shared.saveReceipts(receipts)
}

// Delete receipt
var receipts = LocalStorageService.shared.getReceipts()
receipts.removeAll { $0.id == receiptToDelete.id }
LocalStorageService.shared.saveReceipts(receipts)
```

### Using CurrencyManager

```swift
// Convert currency
let usdAmount = 100.0
let eurAmount = CurrencyManager.shared.convertAmountSync(
    usdAmount,
    from: "USD",
    to: "EUR"
)
print("$\(usdAmount) = €\(eurAmount)")

// Format currency
let formatted = CurrencyManager.shared.formatAmount(
    1234.56,
    currencyCode: "USD"
)
print(formatted) // "$1,234.56"

// Get preferred currency
let preferred = CurrencyManager.shared.preferredCurrency
print("Preferred: \(preferred)")

// Set preferred currency
CurrencyManager.shared.preferredCurrency = "EUR"
```

---

## Common Patterns

### Creating a Receipt Model

```swift
let receipt = Receipt(
    id: UUID(),
    user_id: userId,
    image_urls: ["https://example.com/image.jpg"],
    total_amount: 45.99,
    items: [
        ReceiptItem(
            id: UUID(),
            name: "Coffee",
            price: 4.50,
            category: "Dining"
        ),
        ReceiptItem(
            id: UUID(),
            name: "Bagel",
            price: 3.25,
            category: "Dining"
        )
    ],
    store_name: "Starbucks",
    store_address: "123 Main St",
    receipt_name: "Starbucks",
    purchase_date: Date(),
    currency: "USD",
    payment_method: "Credit Card",
    total_tax: 0.65,
    logo_search_term: "Starbucks"
)
```

### Converting Receipt to Dictionary (for API)

```swift
let receipt = Receipt(/* ... */)

// Convert to dictionary for API
let receiptDict = try receipt.toDictionary()

// Use with JSON serialization
let jsonData = try JSONSerialization.data(withJSONObject: receiptDict)
let jsonString = String(data: jsonData, encoding: .utf8)
```

### Converting Dictionary to Receipt

```swift
let receiptDict: [String: Any] = [
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "660e8400-e29b-41d4-a716-446655440000",
    "store_name": "Walmart",
    "total_amount": 123.45,
    // ... more fields
]

// Create Receipt from dictionary
let receipt = try Receipt.fromDictionary(receiptDict)
```

### Async/Await Pattern

```swift
func processReceipt(image: UIImage) async throws -> Receipt {
    // Step 1: Upload image
    let imageURL = await ImageStorageService.shared.uploadImage(image)
    
    // Step 2: Extract data with AI
    let response = try await AIService.shared.generateContent(
        prompt: "Extract receipt...",
        image: image
    )
    
    // Step 3: Parse response
    guard let receipt = parseReceipt(from: response.text) else {
        throw ReceiptError.parsingFailed
    }
    
    // Step 4: Update image URL
    receipt.image_urls = [imageURL]
    
    return receipt
}

// Call from view
Task {
    do {
        let receipt = try await processReceipt(image: selectedImage)
        // Use receipt
    } catch {
        print("Error: \(error)")
    }
}
```

### Error Handling Pattern

```swift
enum ReceiptError: Error {
    case imageProcessingFailed
    case aiExtractionFailed
    case parsingFailed
    case networkError(Error)
}

func processReceipt(image: UIImage) async throws -> Receipt {
    do {
        // Try AI extraction
        let response = try await AIService.shared.generateContent(
            prompt: "Extract receipt...",
            image: image
        )
        
        guard let receipt = parseReceipt(from: response.text) else {
            throw ReceiptError.parsingFailed
        }
        
        return receipt
    } catch let error as AIServiceError {
        // Handle specific AI errors
        switch error {
        case .rateLimited:
            throw ReceiptError.networkError(error)
        case .authenticationFailed:
            throw ReceiptError.networkError(error)
        default:
            throw ReceiptError.aiExtractionFailed
        }
    } catch {
        // Handle other errors
        throw ReceiptError.networkError(error)
    }
}
```

---

## Testing Examples

### Mock Services for Testing

```swift
// Mock AIService for testing
class MockAIService {
    static let shared = MockAIService()
    
    func generateContent(
        prompt: String,
        image: UIImage?,
        systemInstruction: String?,
        config: AIService.GenerationConfig?
    ) async throws -> AIResponse {
        // Return mock response
        return AIResponse(text: """
        {
            "isValid": true,
            "store_name": "Test Store",
            "total_amount": 10.00,
            "items": [
                {"name": "Test Item", "price": 10.00, "category": "Other"}
            ]
        }
        """)
    }
}

// Use in previews
struct NewExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseView(onReceiptAdded: { _ in })
            .environmentObject(createMockAppState())
    }
    
    static func createMockAppState() -> AppState {
        let appState = AppState()
        appState.useLocalStorage = true
        return appState
    }
}
```

### Unit Test Example

```swift
import XCTest

class ReceiptParsingTests: XCTestCase {
    func testParseReceiptFromJSON() {
        let jsonString = """
        {
            "isValid": true,
            "store_name": "Starbucks",
            "total_amount": 8.40,
            "items": [
                {"name": "Coffee", "price": 4.50, "category": "Dining"},
                {"name": "Bagel", "price": 3.25, "category": "Dining"}
            ]
        }
        """
        
        let receipt = parseReceipt(from: jsonString)
        
        XCTAssertNotNil(receipt)
        XCTAssertEqual(receipt?.store_name, "Starbucks")
        XCTAssertEqual(receipt?.total_amount, 8.40)
        XCTAssertEqual(receipt?.items.count, 2)
    }
}
```

### Preview with Sample Data

```swift
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppState = AppState()
        mockAppState.useLocalStorage = true
        
        // Pre-populate with sample receipts
        let sampleReceipts = createSampleReceipts()
        LocalStorageService.shared.saveReceipts(sampleReceipts)
        
        return DashboardView(email: "test@example.com")
            .environmentObject(mockAppState)
    }
    
    static func createSampleReceipts() -> [Receipt] {
        return [
            Receipt(
                id: UUID(),
                user_id: UUID(),
                image_urls: [],
                total_amount: 10.00,
                items: [
                    ReceiptItem(id: UUID(), name: "Item 1", price: 10.00, category: "Other")
                ],
                store_name: "Test Store",
                store_address: "123 Test St",
                receipt_name: "Test Store",
                purchase_date: Date(),
                currency: "USD",
                payment_method: "Credit Card",
                total_tax: 0.00,
                logo_search_term: "Test Store"
            )
        ]
    }
}
```

---

## Quick Reference

### Common Service Calls

```swift
// Backend API
BackendAPIService.shared.generateAIContent(...)
BackendAPIService.shared.uploadImage(...)
BackendAPIService.shared.signInWithApple(...)

// AI Service
AIService.shared.generateContent(...)
AIService.shared.validateReceipt(...)

// Storage
LocalStorageService.shared.addReceipt(...)
LocalStorageService.shared.getReceipts()

// Images
ImageStorageService.shared.uploadImage(...)

// Currency
CurrencyManager.shared.convertAmountSync(...)
CurrencyManager.shared.formatAmount(...)
```

### Common View Patterns

```swift
// Environment Object
@EnvironmentObject var appState: AppState

// State
@State private var isLoading = false

// Async task in view
Task {
    await fetchData()
}

// Sheet presentation
.sheet(isPresented: $showSheet) {
    SomeView()
}

// Navigation
NavigationView {
    SomeView()
}
```

---

## Tips & Best Practices

1. **Always use async/await** for network calls
2. **Handle errors properly** with try/catch
3. **Use environment objects** for shared state
4. **Pre-populate preview data** for fast previews
5. **Mock services** for testing
6. **Check network availability** before API calls
7. **Use local storage** for offline functionality
8. **Compress images** before uploading
9. **Validate receipts** before processing
10. **Cache responses** when appropriate

---

*For more detailed information, see the [Overview](overview.md) and [UI Flow](ui_flow.md) documentation.*

