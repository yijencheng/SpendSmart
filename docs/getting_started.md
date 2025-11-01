## Getting Started

### Understanding the Codebase

1. **Start with the App Entry:** Read `SpendSmartApp.swift` to understand app initialization
2. **Follow the Navigation:** Check `ContentView.swift` to see how screens are organized
3. **Explore a Feature:** Pick a feature (e.g., adding a receipt) and trace through:
   - Which view handles it?
   - Which service does the work?
   - How is data stored?
4. **Study the Models:** Understand the data structures in `Models/` folder

### Common Patterns You'll See

1. **Singleton Services:** All services use `static let shared` pattern
2. **Environment Objects:** Views access `AppState` via `@EnvironmentObject`
3. **Async Functions:** Network calls use `async/await`
4. **Codable Models:** Models convert to/from JSON for API communication

### Development Workflow

1. **Adding a New Feature:**
   - Create/update Models if needed
   - Add service methods for business logic
   - Create SwiftUI views for UI
   - Connect everything through `AppState` if sharing state

2. **Debugging:**
   - Check console logs (many services log with emoji prefixes 🚀, ✅, ❌)
   - Verify `AppState` values are correct
   - Ensure services are called correctly

3. **Testing:**
   - Services can be mocked for testing
   - Views can be previewed in Xcode without running the app

---

## Key Takeaways

✅ **Architecture:** MVC with Services layer - clean separation of concerns  
✅ **State Management:** `AppState` is the single source of truth  
✅ **Reactive UI:** Views automatically update when state changes  
✅ **Services:** All external operations go through services  
✅ **Models:** Simple data structures with Codable for API communication  

---

## Next Steps

- Explore the code starting with `SpendSmartApp.swift`
- Read service implementations to understand business logic
- Check out `NewExpenseView.swift` for a complete feature example
- Review SwiftUI documentation for UI concepts

---

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Language Guide](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/)
- [iOS App Architecture](https://developer.apple.com/documentation/technologies)

---

*This overview provides a high-level understanding. For detailed implementation, explore the actual code files.*

