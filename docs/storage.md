# SpendSmart - Storage Architecture

> Comprehensive guide to how the SpendSmart app handles data storage, including current implementation and potential alternatives

## 📖 Table of Contents

1. [Storage Overview](#storage-overview)
2. [Current Storage Strategy](#current-storage-strategy)
3. [Storage Decision Logic](#storage-decision-logic)
4. [Storage Components](#storage-components)
5. [Data Flow](#data-flow)
6. [Storage Alternatives](#storage-alternatives)
7. [Migration Considerations](#migration-considerations)

---

## Storage Overview

SpendSmart uses a **hybrid storage strategy** that adapts based on user authentication status:

- **Guest Mode:** Local storage only (offline-first)
- **Logged In Mode:** Cloud storage (Supabase + Backend API)

This dual approach allows users to:
- Try the app without creating an account (guest mode)
- Sync data across devices (logged in mode)
- Work offline when needed (local fallback)

---

## Current Storage Strategy

### Storage Layers

The app manages three types of data:

1. **Receipt Data** (structured data: store name, items, totals, etc.)
2. **Receipt Images** (binary files: photos of receipts)
3. **User Preferences** (settings, currency preferences, etc.)

### Storage Decision Matrix

| Data Type | Guest Mode | Logged In Mode |
|-----------|------------|----------------|
| **Receipt Data** | UserDefaults (JSON) | Supabase Database |
| **Receipt Images** | Documents Directory | Backend API → imgBB Cloud |
| **User Preferences** | UserDefaults | UserDefaults + Cloud sync (future) |
| **Authentication** | None (local only) | Supabase Auth / Backend API |

---

## Storage Decision Logic

### How the App Chooses Storage

**Location:** `Models/AppState.swift`

The app uses `appState.useLocalStorage` to determine storage strategy:

```swift
if appState.useLocalStorage {
    // Guest mode → Local storage
    LocalStorageService.shared.addReceipt(newReceipt)
} else {
    // Logged in → Cloud database
    supabase.createReceipt(newReceipt)
}
```

### Storage Mode Detection

The app determines storage mode during initialization:

1. **Guest Mode (useLocalStorage = true):**
   - User selects "Continue as Guest"
   - No authentication required
   - All data stored locally

2. **Logged In Mode (useLocalStorage = false):**
   - User signs in with Apple ID or backend API
   - Data synced to cloud
   - Cross-device access enabled

---

## Storage Components

### 1. Receipt Data Storage

#### Guest Mode: UserDefaults

**Location:** `Services/LocalStorageService.swift`

**Implementation:**
- Stores receipt data as JSON in `UserDefaults`
- Key: `"local_receipts"`
- Format: Array of `Receipt` objects encoded as JSON

**Code:**
```swift
func saveReceipts(_ receipts: [Receipt]) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(dateFormatter)
    let data = try encoder.encode(receipts)
    UserDefaults.standard.set(data, forKey: "local_receipts")
}
```

**Pros:**
- ✅ Fast access (in-memory cache)
- ✅ No network required
- ✅ Simple implementation
- ✅ Works offline

**Cons:**
- ❌ Limited size (~1MB recommended)
- ❌ Not suitable for large datasets
- ❌ No cross-device sync
- ❌ Data lost if app deleted

#### Logged In Mode: Supabase Database

**Location:** `SupabaseManager.swift`

**Implementation:**
- PostgreSQL database hosted by Supabase
- Table: `receipts`
- Uses Row-Level Security (RLS) for user isolation

**Code:**
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

**Pros:**
- ✅ Cloud storage (accessible anywhere)
- ✅ Cross-device synchronization
- ✅ Automatic backups
- ✅ Scalable (handles large datasets)
- ✅ Real-time sync capability

**Cons:**
- ❌ Requires internet connection
- ❌ Depends on Supabase service
- ❌ Authentication required
- ❌ Potential costs at scale

**Database Schema:**
```sql
CREATE TABLE receipts (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    image_urls TEXT[],
    total_amount DOUBLE PRECISION,
    items JSONB,
    store_name TEXT,
    store_address TEXT,
    receipt_name TEXT,
    purchase_date TIMESTAMP,
    currency TEXT,
    payment_method TEXT,
    total_tax DOUBLE PRECISION,
    logo_search_term TEXT
);
```

---

### 2. Image Storage

#### Guest Mode: Documents Directory

**Location:** `Services/ImageStorageService.swift` (fallback method)

**Implementation:**
- Images saved to app's Documents directory
- Filename format: `receipt_{timestamp}_{random}.jpg`
- URL format: `local://receipt_123456789_12345.jpg`

**Code:**
```swift
private func saveImageLocally(_ image: UIImage) async -> String {
    let filename = "receipt_\(Int(timestamp))_\(randomNum).jpg"
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentsDirectory.appendingPathComponent(filename)
    
    let imageData = image.jpegData(compressionQuality: 0.7)
    try imageData.write(to: fileURL)
    
    return "local://\(filename)"
}
```

**Pros:**
- ✅ No network required
- ✅ Fast local access
- ✅ No external dependencies
- ✅ Privacy (stays on device)

**Cons:**
- ❌ Limited by device storage
- ❌ Not accessible across devices
- ❌ Lost if app deleted
- ❌ No backup by default

#### Logged In Mode: Backend API → Cloud Storage (imgBB)

**Location:** `Services/ImageStorageService.swift`

**Implementation:**
- Images uploaded to backend API (`/api/images/upload`)
- Backend uploads to imgBB cloud storage
- Returns public URL for image

**Flow:**
```
Image → Resize (1000x1000px) → Convert to base64 → Backend API → imgBB → Return URL
```

**Code:**
```swift
func uploadImage(_ image: UIImage) async -> String {
    let resizedImage = resizeImage(image, targetSize: CGSize(width: 1000, height: 1000))
    
    do {
        // Try backend API first
        let response = try await backendAPI.uploadImage(resizedImage)
        return response.data.url
    } catch {
        // Fallback to local storage if backend fails
        return await saveImageLocally(resizedImage)
    }
}
```

**Pros:**
- ✅ Cloud storage (accessible anywhere)
- ✅ Cross-device access
- ✅ Automatic backups
- ✅ Public URLs for sharing
- ✅ No device storage used
- ✅ Fallback to local if network fails

**Cons:**
- ❌ Requires internet connection
- ❌ Depends on imgBB service
- ❌ Potential costs at scale
- ❌ Privacy concerns (images on third-party service)

**Image Processing:**
- **Resizing:** Max 1000x1000px before upload
- **Compression:** JPEG at 80% quality
- **Encoding:** Base64 for API transmission

---

### 3. User Preferences Storage

**Location:** `UserDefaults` (both modes)

**Stored Data:**
- Currency preferences (`CurrencyManager`)
- Onboarding completion status
- Guest user ID
- Last version check date
- App settings

**Code Example:**
```swift
UserDefaults.standard.set(preferredCurrency, forKey: "preferred_currency")
UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
```

---

## Data Flow

### Receipt Creation Flow

#### Guest Mode:
```
User captures image
    ↓
AI processes (backend API)
    ↓
Receipt data created
    ↓
Save to UserDefaults (LocalStorageService)
    ↓
Images saved to Documents directory
    ↓
receipt.image_urls = ["local://..."]
    ↓
Receipt complete (stored locally)
```

#### Logged In Mode:
```
User captures image
    ↓
AI processes (backend API)
    ↓
Receipt data created
    ↓
Upload images to backend API → imgBB
    ↓
receipt.image_urls = ["https://i.ibb.co/.../image.jpg"]
    ↓
Save receipt to Supabase database
    ↓
Receipt synced to cloud
```

### Image Upload Flow (Both Modes)

```
Image Selected
    ↓
Resize (1000x1000px)
    ↓
┌───────────┴───────────┐
│                       │
Guest Mode          Logged In Mode
│                       │
↓                       ↓
Save to Documents    Try Backend API
Directory                │
│                       ↓
│                   Success? ──Yes──→ imgBB Cloud Storage
│                       │               Return URL
│                       │
│                   └───No──→ Fallback to Documents Directory
│
Both end with: receipt.image_urls populated
```

---

## Storage Alternatives

### Receipt Data Storage Alternatives

#### 1. Core Data (iOS Native)

**What it is:**
- Apple's native object graph persistence framework
- SQLite database under the hood
- Built into iOS SDK

**Pros:**
- ✅ Native iOS solution
- ✅ Powerful querying
- ✅ Relationship management
- ✅ Migration support
- ✅ Works offline
- ✅ Better performance for large datasets

**Cons:**
- ❌ iOS only (no cross-platform)
- ❌ More complex than UserDefaults
- ❌ Steeper learning curve
- ❌ No built-in cloud sync

**When to Use:**
- Need complex queries and relationships
- Large datasets (1000+ receipts)
- Offline-first app
- iOS-only app

**Migration Effort:** Medium

---

#### 2. SQLite (Direct)

**What it is:**
- Lightweight SQL database
- File-based storage
- Cross-platform

**Pros:**
- ✅ Simple SQL queries
- ✅ Cross-platform (iOS, Android, etc.)
- ✅ Works offline
- ✅ Better performance than UserDefaults
- ✅ Small footprint

**Cons:**
- ❌ Manual schema management
- ❌ No built-in sync
- ❌ More boilerplate code
- ❌ Migration complexity

**When to Use:**
- Need SQL queries
- Cross-platform app
- Want full control over database

**Migration Effort:** Medium-High

---

#### 3. Realm Database

**What it is:**
- Object database with real-time sync
- MongoDB's mobile database solution

**Pros:**
- ✅ Real-time sync built-in
- ✅ Offline-first architecture
- ✅ Easy to use (object-oriented)
- ✅ Cross-platform
- ✅ Automatic migrations

**Cons:**
- ❌ Additional dependency
- ❌ File size increases
- ❌ License considerations (commercial use)
- ❌ Sync service costs

**When to Use:**
- Need real-time sync
- Offline-first requirements
- Cross-platform app
- Budget for Realm Cloud

**Migration Effort:** High

---

#### 4. Firebase Firestore

**What it is:**
- Google's NoSQL cloud database
- Real-time sync capability

**Pros:**
- ✅ Real-time updates
- ✅ Automatic offline caching
- ✅ Easy setup
- ✅ Scalable
- ✅ Cross-platform

**Cons:**
- ❌ Google dependency
- ❌ Costs can scale with usage
- ❌ NoSQL (different from current SQL model)
- ❌ Privacy concerns (Google ecosystem)

**When to Use:**
- Need real-time sync
- Want Firebase ecosystem integration
- Google Cloud infrastructure preferred

**Migration Effort:** High

---

#### 5. CloudKit (Apple)

**What it is:**
- Apple's cloud database service
- Integrated with iCloud

**Pros:**
- ✅ Free for users (iCloud account)
- ✅ Native iOS integration
- ✅ Automatic sync
- ✅ Privacy-focused (end-to-end encryption)
- ✅ No additional costs for basic usage

**Cons:**
- ❌ iOS/macOS only
- ❌ Requires iCloud account
- ❌ Limited query capabilities
- ❌ Apple ecosystem lock-in

**When to Use:**
- iOS-only app
- Want free cloud storage
- Apple ecosystem preferred
- Privacy is priority

**Migration Effort:** Medium-High

---

### Image Storage Alternatives

#### 1. AWS S3 + CloudFront

**What it is:**
- Amazon's object storage service
- CDN for fast global access

**Pros:**
- ✅ Highly scalable
- ✅ Reliable (99.99% uptime)
- ✅ Global CDN
- ✅ Fine-grained access control
- ✅ Cost-effective at scale

**Cons:**
- ❌ More complex setup
- ❌ AWS account required
- ❌ Cost monitoring needed
- ❌ More infrastructure to manage

**When to Use:**
- Large-scale app
- Need enterprise-grade reliability
- Already using AWS services

**Migration Effort:** Medium

---

#### 2. Google Cloud Storage

**What it is:**
- Google's object storage service
- Similar to AWS S3

**Pros:**
- ✅ Scalable
- ✅ Integrated with Google services
- ✅ Good performance
- ✅ Cost-effective

**Cons:**
- ❌ Google dependency
- ❌ Setup complexity
- ❌ Cost monitoring needed

**When to Use:**
- Using Google Cloud Platform
- Need enterprise storage solution

**Migration Effort:** Medium

---

#### 3. Firebase Storage

**What it is:**
- Google's Firebase cloud storage
- Integrated with Firestore

**Pros:**
- ✅ Easy integration with Firestore
- ✅ Built-in security rules
- ✅ Automatic CDN
- ✅ Simple API

**Cons:**
- ❌ Google dependency
- ❌ Costs can scale
- ❌ Firebase ecosystem lock-in

**When to Use:**
- Using Firestore for data
- Want integrated solution
- Firebase ecosystem preferred

**Migration Effort:** Low-Medium (if already using Firebase)

---

#### 4. CloudKit Assets (Apple)

**What it is:**
- Store large files in CloudKit
- Integrated with iCloud

**Pros:**
- ✅ Free for users (iCloud account)
- ✅ Native iOS integration
- ✅ Automatic sync
- ✅ Privacy-focused
- ✅ No additional costs

**Cons:**
- ❌ iOS/macOS only
- ❌ Requires iCloud account
- ❌ Storage limits per user
- ❌ Apple ecosystem only

**When to Use:**
- iOS-only app
- Want free storage
- Privacy priority
- Apple ecosystem preferred

**Migration Effort:** Medium

---

#### 5. Direct Backend Storage

**What it is:**
- Store images on your own backend server
- Full control over storage

**Pros:**
- ✅ Full control
- ✅ No third-party dependencies
- ✅ Custom policies
- ✅ Data sovereignty

**Cons:**
- ❌ Infrastructure management
- ❌ Server costs
- ❌ CDN setup needed
- ❌ Backup responsibility

**When to Use:**
- Want complete control
- Have infrastructure team
- Compliance requirements
- Custom storage needs

**Migration Effort:** High

---

#### 6. Keep Current: imgBB (with fallback)

**Current Implementation:**
- imgBB via backend API
- Fallback to local storage

**Pros:**
- ✅ Already implemented
- ✅ Works well for current scale
- ✅ Has fallback mechanism
- ✅ Simple API

**Cons:**
- ❌ Third-party dependency
- ❌ Costs at scale
- ❌ Limited control

**Recommendation:** Keep for now, migrate when scaling

---

### Combined Storage Alternatives

#### Option 1: Offline-First with Sync

**Strategy:**
- Local storage (Core Data/SQLite) as primary
- Periodic sync to cloud (Supabase/Firebase)
- Works offline, syncs when online

**Pros:**
- ✅ Works completely offline
- ✅ Fast local access
- ✅ Sync when convenient
- ✅ Better user experience

**Cons:**
- ❌ Conflict resolution needed
- ❌ More complex implementation
- ❌ Sync logic complexity

**When to Use:**
- Offline capability is critical
- Users may have poor connectivity
- Want best of both worlds

---

#### Option 2: Cloud-First with Caching

**Strategy:**
- Cloud storage (Supabase/Firebase) as primary
- Local cache for offline access
- Sync-first approach

**Pros:**
- ✅ Always synced
- ✅ Cross-device consistency
- ✅ Automatic backups
- ✅ Simplified logic (single source of truth)

**Cons:**
- ❌ Requires internet for writes
- ❌ Slower than local-first
- ❌ More network usage

**When to Use:**
- Internet usually available
- Cross-device sync is priority
- Cloud-first architecture

---

## Migration Considerations

### From Current to Alternative Storage

#### Migrating from UserDefaults to Core Data

**Steps:**
1. Create Core Data model
2. Write migration code to convert existing data
3. Update `LocalStorageService` to use Core Data
4. Test thoroughly before release

**Code Structure:**
```swift
// Migration example
class LocalStorageService {
    func migrateFromUserDefaults() {
        let oldReceipts = getReceiptsFromUserDefaults()
        for receipt in oldReceipts {
            saveToCoreData(receipt)
        }
        UserDefaults.standard.removeObject(forKey: "local_receipts")
    }
}
```

---

#### Migrating from Supabase to CloudKit

**Considerations:**
- Different data models
- Migration scripts needed
- User data migration
- Downtime planning

**Steps:**
1. Set up CloudKit containers
2. Create CloudKit schema
3. Write migration scripts
4. Migrate user data
5. Update app code
6. Test sync functionality

---

### Backward Compatibility

**Important:** Any storage migration should maintain backward compatibility:

1. **Read both old and new storage** during transition
2. **Migrate data gradually** (lazy migration)
3. **Keep old storage** until migration verified
4. **Provide rollback mechanism** if needed

---

## Current Storage Limitations

### UserDefaults Limitations

- **Size limit:** ~1MB recommended
- **Performance:** Slows down with large datasets
- **Query capabilities:** Limited (need to load all data)

**When to Migrate:**
- User has 500+ receipts
- App feels slow loading receipts
- Need complex queries

---

### Supabase Limitations

- **Internet dependency:** Requires connection
- **Costs:** Can scale with usage
- **Lock-in:** Migrating away is complex
- **RLS complexity:** Row-level security can be tricky

**When to Consider Alternatives:**
- Need offline-first capability
- Want more control over data
- Cost concerns at scale

---

## Recommendations

### For Current Scale (< 10k users)

✅ **Keep Current Setup:**
- UserDefaults for guest mode (works fine)
- Supabase for logged in (reliable, easy)
- imgBB for images (simple, works)

### For Growth (10k - 100k users)

🔄 **Consider Migrating:**
- **Receipt Data:** Core Data for guest mode, keep Supabase for cloud
- **Images:** Evaluate AWS S3 or CloudKit for better scalability
- **Sync:** Add offline-first capabilities

### For Scale (100k+ users)

🔄 **Plan Migration:**
- **Receipt Data:** Realm or CloudKit for better sync
- **Images:** AWS S3 + CloudFront for performance
- **Architecture:** Consider microservices for storage

---

## Best Practices

1. **Always have a fallback:** Cloud → Local if network fails
2. **Lazy loading:** Load data as needed, not all at once
3. **Caching:** Cache frequently accessed data locally
4. **Sync strategy:** Clear sync rules (last-write-wins, conflict resolution)
5. **Error handling:** Graceful degradation when storage fails
6. **Testing:** Test offline scenarios thoroughly
7. **Migration:** Always maintain backward compatibility

---

## Summary

**Current Architecture:**
- **Guest Mode:** UserDefaults (receipts) + Documents (images)
- **Logged In Mode:** Supabase (receipts) + imgBB (images)
- **Strategy:** Cloud-first with local fallback

**Key Strengths:**
- ✅ Simple implementation
- ✅ Works offline (guest mode)
- ✅ Syncs across devices (logged in)
- ✅ Fallback mechanisms in place

**Areas for Improvement:**
- 🔄 Migrate guest mode to Core Data for better performance
- 🔄 Consider CloudKit for native iOS cloud storage
- 🔄 Add offline-first sync for logged in users
- 🔄 Evaluate image storage alternatives at scale

---

*For implementation details, see the service files:*
- `Services/LocalStorageService.swift` - Local receipt storage
- `Services/ImageStorageService.swift` - Image upload logic
- `SupabaseManager.swift` - Cloud database operations

