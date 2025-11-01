# SpendSmart - UI Flow: Creating a New Expense

> A detailed walkthrough of the user flow when creating a new expense, including camera/gallery selection, API interactions, and database operations

## 📖 Table of Contents

1. [Overview](#overview)
2. [Initial User Action](#initial-user-action)
3. [Image Selection Options](#image-selection-options)
4. [Receipt Processing Flow](#receipt-processing-flow)
5. [API Interactions](#api-interactions)
6. [Database Operations](#database-operations)
7. [Complete Flow Diagram](#complete-flow-diagram)

---

## Overview

When a user wants to add a new receipt expense, the app goes through several stages:

1. **Image Capture/Selection** → User chooses camera or gallery
2. **AI Processing** → Receipt image is analyzed and data extracted
3. **Image Upload** → Receipt images are stored (cloud or local)
4. **Data Storage** → Receipt data is saved to database
5. **UI Update** → Dashboard refreshes to show new receipt

---

## Initial User Action

### Starting Point: DashboardView

**Location:** `Views/DashboardView.swift`

```swift
Button {
    showNewExpenseSheet.toggle()
} label: {
    // "New Expense" button
}
```

**What happens:**
- User taps the "New Expense" button (floating action button at bottom)
- `showNewExpenseSheet` state variable is set to `true`
- `NewExpenseView` opens as a **sheet** (modal overlay)

**Key Components:**
- `DashboardView`: Main screen displaying spending summary and charts
- Floating Action Button (FAB): Always visible at bottom of screen
- Sheet Presentation: `NewExpenseView` slides up from bottom

---

## Image Selection Options

After `NewExpenseView` opens, the user sees two options:

### Option 1: Camera 📷

**Location:** `Views/NewExpenseView.swift` (lines 250-275)

**What happens:**
1. User taps "Camera" button
2. `showMultiCamera` state is set to `true`
3. `MultiImageCaptureView` opens as a sheet
4. **Camera Interface** appears:
   - Live camera preview
   - Capture button
   - Ability to take multiple photos
   - Preview of captured images

**Implementation Details:**
- **Component:** `Views/HelperViews/MultiImageCaptureView.swift`
- **Technology:** Uses `AVFoundation` framework
- **Features:**
  - Real-time camera preview
  - Multi-image capture (for long receipts)
  - Image preview after capture
  - Camera controls (flash, flip, etc.)

**Data Flow:**
```
User taps "Camera"
    ↓
showMultiCamera = true
    ↓
MultiImageCaptureView sheet opens
    ↓
User takes photo(s)
    ↓
capturedImages array updated
    ↓
Sheet closes, images displayed in NewExpenseView
```

**Key State Variables:**
- `@State private var showMultiCamera: Bool`
- `@State private var capturedImages: [UIImage]`

---

### Option 2: Gallery 🖼️

**Location:** `Views/NewExpenseView.swift` (lines 277-294)

**What happens:**
1. User taps "Gallery" button
2. `showImagePicker` state is set to `true`
3. `MultiImagePicker` opens (iOS photo picker)
4. **Photo Library Interface** appears:
   - Grid of user's photos
   - Ability to select multiple images
   - Preview selected images

**Implementation Details:**
- **Component:** `Views/HelperViews/MultiImagePicker.swift`
- **Technology:** Uses `PhotosUI` framework (PHPickerViewController)
- **Features:**
  - Native iOS photo picker
  - Multi-image selection
  - Access to user's photo library
  - Image loading asynchronously

**Data Flow:**
```
User taps "Gallery"
    ↓
showImagePicker = true
    ↓
MultiImagePicker sheet opens (iOS photo picker)
    ↓
User selects image(s) from library
    ↓
capturedImages array updated
    ↓
Sheet closes, images displayed in NewExpenseView
```

**Key State Variables:**
- `@State private var showImagePicker: Bool`
- `@State private var capturedImages: [UIImage]`

---

## Receipt Processing Flow

Once images are selected/captured, user taps **"Process Receipt"** button.

### Processing Steps

The app goes through these UI states:

1. **"Validating Receipt"** (1.5 seconds)
2. **"Analyzing Receipt"** (0.5 seconds) 
3. **"Saving to Database"** (varies based on image count)
4. **"Complete!"** (0.4 seconds)

**Location:** `Views/NewExpenseView.swift` (lines 312-453)

### Step-by-Step Processing

#### Step 1: Validate Receipt (UI State)

```swift
progressStep = .validatingReceipt
```

**What happens:**
- Progress indicator shows "Validating Receipt"
- 1.5 second delay for UX (shows progress)

#### Step 2: Analyze Receipt

```swift
progressStep = .analyzingReceipt
```

**What happens:**
- Calls `extractDataFromImage(receiptImage:)` function
- **This is where the AI magic happens!**

#### Step 3: Extract Data from Image

**Location:** `Views/NewExpenseView.swift` (lines 658-841)

**Function:** `extractDataFromImage(receiptImage: UIImage) async -> Receipt?`

**Process:**

1. **Create AI Prompt:**
   ```swift
   let systemPrompt = """
   ### SpendSmart Receipt Extraction and Validation System
   
   #### CRITICAL: Receipt Validation First
   - Validate if image contains valid receipt
   - Extract: store name, date, items, totals, etc.
   - Categorize items, detect discounts
   - Calculate totals accurately
   """
   ```

2. **Call AI Service:**
   ```swift
   let response = try await aiService.generateContent(
       prompt: prompt,
       image: receiptImage,
       systemInstruction: systemPrompt,
       config: config
   )
   ```

3. **Parse JSON Response:**
   ```swift
   let parsedReceipt = parseReceipt(from: response.text)
   ```

4. **Validate & Create Receipt Model:**
   - Checks if `isValid: false` → returns `nil` (shows error)
   - If valid, creates `Receipt` object with extracted data

**Key Functions:**
- `extractDataFromImage()`: Main extraction function
- `parseReceipt()`: Converts JSON string to `Receipt` model
- `AIService.shared.generateContent()`: Calls backend API

---

## API Interactions

### AI Processing API

**Flow:** `NewExpenseView` → `AIService` → `BackendAPIService` → **Backend Server**

#### 1. AIService Layer

**Location:** `Services/GeminiAPIService.swift` (renamed to AIService)

```swift
func generateContent(
    prompt: String,
    image: UIImage?,
    systemInstruction: String?,
    config: GenerationConfig?
) async throws -> AIResponse
```

**What it does:**
- Prepares request with image and prompt
- Converts `UIImage` to base64 if needed
- Calls `BackendAPIService.shared.generateAIContent()`

**Key Details:**
- Handles both Gemini and OpenAI (unified interface)
- Manages errors and converts backend errors to app errors
- Returns unified `AIResponse` structure

#### 2. BackendAPIService Layer

**Location:** `Services/BackendAPIService.swift` (lines 225-261)

```swift
func generateAIContent(
    prompt: String,
    image: UIImage? = nil,
    systemInstruction: String? = nil,
    config: [String: Any]? = nil
) async throws -> AIContentResponse
```

**What it does:**
- Creates HTTP POST request to `/api/ai/generate`
- Converts image to base64 JPEG
- Sends request to backend server
- Returns AI response with extracted receipt data

**Backend API Endpoint:**
```
POST /api/ai/generate
Headers:
  - Content-Type: application/json
Body:
  {
    "prompt": "Extract all receipt details...",
    "image": "data:image/jpeg;base64,{base64Image}",
    "systemInstruction": "{systemPrompt}",
    "config": { ... }
  }
```

**Backend Processing:**
- Receives image and prompt
- Sends to AI service (Gemini 2.0 Flash or OpenAI)
- AI extracts receipt data:
  - Store name & address
  - Purchase date
  - Items with prices
  - Categories
  - Tax amount
  - Total amount
  - Payment method
- Returns JSON response

**Response Format:**
```json
{
  "response": {
    "text": "{\"isValid\": true, \"store_name\": \"...\", \"items\": [...]}"
  }
}
```

---

### Image Upload API

**Flow:** `NewExpenseView` → `ImageStorageService` → `BackendAPIService` → **Backend Server**

#### 1. ImageStorageService Layer

**Location:** `Services/ImageStorageService.swift`

```swift
func uploadImage(_ image: UIImage) async -> String
```

**What it does:**
1. **Resizes image** to max 1000x1000px (reduces upload size)
2. **Tries backend upload first:**
   - Calls `BackendAPIService.shared.uploadImage()`
3. **Falls back to local storage** if backend fails:
   - Saves to app's documents directory
   - Returns `local://filename.jpg` URL

**Strategy:** Cloud-first with local fallback

#### 2. BackendAPIService Image Upload

**Location:** `Services/BackendAPIService.swift` (lines 286-305)

```swift
func uploadImage(_ image: UIImage) async throws -> ImageUploadResponse
```

**What it does:**
- Creates HTTP POST request to `/api/images/upload`
- Converts image to base64 JPEG
- Sends to backend server
- Backend uploads to cloud storage (imgBB or similar)
- Returns URL where image is stored

**Backend API Endpoint:**
```
POST /api/images/upload
Headers:
  - Content-Type: application/json
  - Authorization: Bearer {token} (if logged in)
Body:
  {
    "image": "data:image/jpeg;base64,{base64Image}"
  }
```

**Response Format:**
```json
{
  "success": true,
  "data": {
    "url": "https://i.ibb.co/.../image.jpg",
    "provider": "ImgBB"
  }
}
```

**Multiple Images:**
For multi-image receipts, `BackendAPIService` also supports:
```swift
func uploadImages(_ images: [UIImage]) async throws -> MultipleImageUploadResponse
```
- Endpoint: `/api/images/upload-multiple`
- Returns array of URLs

---

## Database Operations

After AI processing and image upload complete, the receipt is saved to the database.

### Saving Receipt Data

**Location:** `Views/DashboardView.swift` (lines 84-100)

**Function:** `insertReceipt(newReceipt: Receipt) async`

**Decision Logic:**

```swift
if appState.useLocalStorage {
    // Guest mode → Local storage
    LocalStorageService.shared.addReceipt(newReceipt)
} else {
    // Logged in → Cloud database
    supabase.createReceipt(newReceipt)
}
```

---

### Option 1: Guest Mode (Local Storage)

**Location:** `Services/LocalStorageService.swift`

**What happens:**
- Receipt data is saved to `UserDefaults` or JSON file
- Images are saved to app's documents directory
- No backend communication needed
- Data persists only on device

**Storage Method:**
- Uses `UserDefaults` or file-based JSON storage
- Images stored as files in app's documents directory
- Receipts retrieved from local storage when app opens

**Use Case:** Users who want to try app without creating account

---

### Option 2: Logged In Mode (Cloud Database)

**Location:** `SupabaseManager.swift` (lines 198-209)

**What happens:**
- Receipt data is sent to Supabase database
- Uses Supabase client with authenticated session
- Insert into `receipts` table

**Database Operation:**

```swift
func createReceipt(_ receipt: Receipt) async throws -> Receipt {
    let response: Receipt = try await supabaseClient
        .from("receipts")
        .insert(receipt)
        .select()
        .single()
        .execute()
        .value
    
    return response
}
```

**Supabase Database Structure:**

**Table:** `receipts`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to users |
| `image_urls` | String[] | Array of image URLs |
| `total_amount` | Double | Total amount spent |
| `items` | JSONB | Array of receipt items |
| `store_name` | String | Store/merchant name |
| `store_address` | String | Store location |
| `receipt_name` | String | Receipt title |
| `purchase_date` | Timestamp | Date of purchase |
| `currency` | String | Currency code (USD, EUR, etc.) |
| `payment_method` | String | Payment type |
| `total_tax` | Double | Tax amount |
| `logo_search_term` | String | Brand name for logo search |

**Data Flow:**
```
Receipt Model
    ↓
Receipt.toDictionary() (Extension)
    ↓
SupabaseClient.insert()
    ↓
Supabase Database
    ↓
Returns saved Receipt with database ID
```

**Authentication:**
- Uses Supabase authentication session
- User must be logged in
- Row-level security (RLS) ensures users only see their receipts

---

### UI Refresh

After saving, the dashboard refreshes:

```swift
await insertReceipt(newReceipt: receipt)
await fetchUserReceipts()  // Refresh the list
```

**Location:** `Views/DashboardView.swift` (lines 27-80)

**Function:** `fetchUserReceipts() async`

**What happens:**
1. Checks `appState.useLocalStorage`:
   - **Guest:** Loads from `LocalStorageService`
   - **Logged in:** Fetches from Supabase
2. Updates `currentUserReceipts` array
3. UI automatically refreshes (SwiftUI reactivity)
4. Charts and summaries recalculate

**Supabase Query:**
```swift
let receipts = try await supabase.fetchReceipts(page: 1, limit: 1000)
```

**Backend Query:**
- SELECT from `receipts` table
- Filter by `user_id = current_user.id`
- Order by `purchase_date DESC`
- Pagination support (page, limit)

---

## Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                User taps "New Expense"                  │
│              (DashboardView button)                     │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│              NewExpenseView Opens (Sheet)                │
└─────────────────────────────────────────────────────────┘
                        ↓
            ┌───────────┴───────────┐
            │                       │
    ┌───────▼────────┐      ┌───────▼────────┐
    │   CAMERA       │      │   GALLERY       │
    │  (MultiImage)  │      │  (PhotoPicker)   │
    └───────┬────────┘      └───────┬────────┘
            │                       │
            └───────────┬───────────┘
                        ↓
          ┌─────────────────────────┐
          │  User captures/selects │
          │      images             │
          └─────────────────────────┘
                        ↓
          ┌─────────────────────────┐
          │  User taps "Process      │
          │      Receipt"            │
          └─────────────────────────┘
                        ↓
        ┌───────────────────────────────┐
        │  Step 1: Validating Receipt    │
        │  (UI Progress Indicator)       │
        └───────────────────────────────┘
                        ↓
        ┌───────────────────────────────┐
        │  Step 2: Analyzing Receipt     │
        │  extractDataFromImage()        │
        └───────────────────────────────┘
                        ↓
        ┌───────────────────────────────┐
        │  AI Processing Chain           │
        │  ┌─────────────────────────┐  │
        │  │ AIService                │  │
        │  │  ↓                       │  │
        │  │ BackendAPIService        │  │
        │  │  ↓                       │  │
        │  │ POST /api/ai/generate    │  │
        │  │  ↓                       │  │
        │  │ Backend Server           │  │
        │  │  ↓                       │  │
        │  │ AI Service (Gemini/AI)   │  │
        │  │  ↓                       │  │
        │  │ Returns JSON receipt data│  │
        │  └─────────────────────────┘  │
        └───────────────────────────────┘
                        ↓
        ┌───────────────────────────────┐
        │  Parse JSON → Receipt Model     │
        │  parseReceipt()                 │
        └───────────────────────────────┘
                        ↓
        ┌───────────────────────────────┐
        │  Step 3: Saving to Database   │
        │  Upload Images                 │
        └───────────────────────────────┘
                        ↓
            ┌───────────┴───────────┐
            │                       │
    ┌───────▼────────┐      ┌───────▼────────┐
    │ Image Upload   │      │ Image Upload    │
    │ ImageStorage   │      │ ImageStorage    │
    │ Service        │      │ Service         │
    └───────┬────────┘      └───────┬────────┘
            │                       │
    ┌───────▼────────┐      ┌───────▼────────┐
    │ Backend API    │      │ Local Storage  │
    │ /api/images/   │      │ (Fallback)     │
    │ upload         │      │                │
    └────────────────┘      └────────────────┘
            │                       │
            └───────────┬───────────┘
                        ↓
          ┌─────────────────────────┐
          │  Save Receipt Data       │
          │  insertReceipt()         │
          └─────────────────────────┘
                        ↓
            ┌───────────┴───────────┐
            │                       │
    ┌───────▼────────┐      ┌───────▼────────┐
    │ Guest Mode     │      │ Logged In      │
    │ LocalStorage   │      │ Supabase DB    │
    │ Service        │      │                │
    │                │      │ INSERT INTO    │
    │ UserDefaults   │      │ receipts       │
    │ / Files        │      │                │
    └───────┬────────┘      └───────┬────────┘
            │                       │
            └───────────┬───────────┘
                        ↓
          ┌─────────────────────────┐
          │  Refresh Dashboard      │
          │  fetchUserReceipts()    │
          └─────────────────────────┘
                        ↓
          ┌─────────────────────────┐
          │  UI Updates             │
          │  • Charts recalculate  │
          │  • List refreshes      │
          │  • Summary updates     │
          └─────────────────────────┘
                        ↓
          ┌─────────────────────────┐
          │  Complete!               │
          │  New receipt visible     │
          └─────────────────────────┘
```

---

## Key Files Reference

| Component | File Path | Purpose |
|-----------|-----------|---------|
| **Main View** | `Views/NewExpenseView.swift` | UI for adding expense |
| **Camera** | `Views/HelperViews/MultiImageCaptureView.swift` | Camera interface |
| **Gallery** | `Views/HelperViews/MultiImagePicker.swift` | Photo picker |
| **AI Service** | `Services/GeminiAPIService.swift` | AI processing wrapper |
| **Backend API** | `Services/BackendAPIService.swift` | HTTP requests to backend |
| **Image Storage** | `Services/ImageStorageService.swift` | Image upload logic |
| **Local Storage** | `Services/LocalStorageService.swift` | Guest mode storage |
| **Database** | `SupabaseManager.swift` | Supabase operations |
| **Dashboard** | `Views/DashboardView.swift` | Main screen & receipt saving |

---

## Summary

1. **User Action:** Taps "New Expense" → Opens `NewExpenseView`
2. **Image Selection:** Camera or Gallery → Images stored in `capturedImages` array
3. **Processing:** 
   - AI extracts receipt data via backend API
   - Images uploaded to cloud storage
   - Receipt model created from AI response
4. **Storage:**
   - Guest mode → Local storage (UserDefaults/files)
   - Logged in → Supabase database (cloud)
5. **UI Update:** Dashboard refreshes automatically

**Key Technologies:**
- **SwiftUI** for UI
- **AVFoundation** for camera
- **PhotosUI** for gallery
- **Backend API** for AI processing
- **Supabase** for cloud database
- **Local Storage** for offline mode

---

*This flow ensures a seamless experience whether users are online, offline, or using guest mode.*

