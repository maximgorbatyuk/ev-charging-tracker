# Filters Implementation Plan

## Analysis of Journey Wallet Filter Implementation

### Overview
Journey Wallet uses a consistent pattern for filter buttons across Transport, Hotels, Documents, and other list views.

### Components Used

#### 1. FilterChip Component (`FilterChip.swift`)
A reusable pill-shaped filter button component:

```swift
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
```

**Key characteristics:**
- Pill-shaped design with rounded corners (20pt radius)
- Orange background when selected, light gray when unselected
- White text when selected, dark text when unselected
- Compact horizontal layout in a ScrollView
- Uses horizontal scrolling for multiple filters

#### 2. Filter Enum Pattern
Filters are defined as `String, CaseIterable` enums with a `displayName` computed property:

**Example - Transport Filter:**
```swift
enum TransportFilter: String, CaseIterable {
    case all
    case upcoming
    case inProgress
    case past

    var displayName: String {
        switch self {
        case .all: return L("transport.filter.all")
        case .upcoming: return L("transport.filter.upcoming")
        case .inProgress: return L("transport.filter.in_progress")
        case .past: return L("transport.filter.past")
        }
    }
}
```

**Example - Hotel Filter:**
```swift
enum HotelFilter: String, CaseIterable {
    case all
    case upcoming
    case active
    case past

    var displayName: String {
        switch self {
        case .all: return L("hotel.filter.all")
        case .upcoming: return L("hotel.filter.upcoming")
        case .active: return L("hotel.filter.active")
        case .past: return L("hotel.filter.past")
        }
    }
}
```

**Example - Document Filter:**
```swift
enum DocumentFilter: String, CaseIterable {
    case all
    case pdf
    case images

    var displayName: String {
        switch self {
        case .all: return L("document.filter.all")
        case .pdf: return L("document.filter.pdf")
        case .images: return L("document.filter.images")
        }
    }
}
```

#### 3. ViewModel Pattern
ViewModels have:
- `selectedFilter` property (enum type)
- `filteredItems` computed property or array
- `applyFilters()` method to filter the data

**Example - Transport List ViewModel:**
```swift
@Observable
class TransportListViewModel {
    var transports: [Transport] = []
    var filteredTransports: [Transport] = []
    var selectedFilter: TransportFilter = .all

    func applyFilters() {
        var result = transports

        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            result = result.filter { $0.isUpcoming }
        case .inProgress:
            result = result.filter { $0.isInProgress }
        case .past:
            result = result.filter { $0.isPast }
        }

        filteredTransports = result
    }
}
```

#### 4. View Implementation Pattern
Views use horizontal ScrollView with HStack of FilterChips:

```swift
private var filterSection: some View {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            ForEach(FilterEnum.allCases, id: \.self) { filter in
                FilterChip(
                    title: filter.displayName,
                    isSelected: viewModel.selectedFilter == filter
                ) {
                    viewModel.selectedFilter = filter
                    viewModel.applyFilters()
                }
            }
        }
    }
}
```

### Summary of Journey Wallet Pattern

**Advantages:**
- **Consistent UI:** All list views use the same FilterChip component
- **Type-safe:** Filter enums are strongly-typed with CaseIterable
- **Localized:** All display strings use `L()` function
- **Scrollable:** Handles many filters with horizontal scrolling
- **Compact:** Pill-shaped design takes minimal vertical space
- **Clear visual feedback:** Orange highlight indicates selection

**Filter Categories by Entity:**
- **Transport:** Status-based (all, upcoming, inProgress, past)
- **Hotel:** Status-based (all, upcoming, active, past)
- **Document:** Type-based (all, pdf, images)
- **Checklist:** Status-based (all, pending, completed)

---

## Current EVChargingTracker Implementation

### Expenses Screen

**Current Implementation:**
- Uses `FilterButtonsView` component (full-width equal buttons)
- Filters defined manually as `FilterButtonItem` array in ViewModel
- Four filters: All, Charges, Repair/maintenance (grouped), Carwash
- **Note:** "Repair" and "Maintenance" are currently combined into a single filter

**Expected Result After Implementation:**
- Uses `FilterChip` component (pill-shaped, horizontal scrolling)
- Filters defined as `ExpensesFilter` enum
- Six filters: All, Charging, Maintenance, Repair, Carwash, Other
- Each ExpenseType gets its own filter button (no grouping)

**Comparison:**

| Current Filter | After Implementation | Change |
|---------------|---------------------|---------|
| Filter.All | All | ✓ Same |
| Filter.Charges | Charging | ✓ Split into individual type |
| Filter.Repair/maintenance | Maintenance | **Split** - Separate filter |
| (none) | Repair | **New** - Separate filter |
| Filter.Carwash | Carwash | ✓ Split into individual type |
| (none) | Other | **New** - Separate filter |

**Current FilterButtonsView:**
```swift
class FilterButtonItem: ObservableObject {
    let id: UUID = UUID()
    let title: String
    @Published var isSelected = false
    private let innerAction: () -> Void
}

struct FilterButtonsView: View {
    let buttonHeight: CGFloat = 44.0
    @State var viewModel: FilterButtonsViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.filterButtons, id: \.id) { button in
                Button(action: { viewModel.executeButtonAction(button) }) {
                    Text(button.title)
                }
                .frame(maxWidth: .infinity, minHeight: buttonHeight, maxHeight: buttonHeight)
                // ... styling with rounded rectangles and opacity
            }
        }
    }
}
```

**ViewModel Implementation:**
```swift
class ExpensesViewModel: ObservableObject {
    @Published var filterButtons: [FilterButtonItem] = []
    private var _currentExpenseTypeFilters: [ExpenseType] = []

    init() {
        self.filterButtons = [
            FilterButtonItem(title: L("Filter.All"), innerAction: { ... }, isSelected: true),
            FilterButtonItem(title: L("Filter.Charges"), innerAction: { ... }),
            FilterButtonItem(title: L("Filter.Repair/maintenance"), innerAction: { ... }),
            FilterButtonItem(title: L("Filter.Carwash"), innerAction: { ... }),
        ]
    }

    func loadSessions(_ expenseTypeFilters: [ExpenseType] = []) {
        _currentExpenseTypeFilters = expenseTypeFilters
        // Load filtered data
    }
}
```

**ExpenseType Enum (already exists):**
```swift
enum ExpenseType: String, CaseIterable, Codable {
    case charging
    case maintenance
    case repair
    case carwash
    case other
}
```

### Planned Maintenance Screen

**Current Implementation:**
- **No filters** - displays all maintenance records
- Uses `PlanedMaintenanceViewModel` with `maintenanceRecords` array
- Records sorted by urgency (overdue first, then by date/mileage)

**PlannedMaintenanceItem Structure:**
```swift
struct PlannedMaintenanceItem: Identifiable, Comparable {
    let id: Int64
    let name: String
    let odometer: Int?
    let when: Date?
    let carId: Int64
    let createdAt: Date

    let mileageDifference: Int?  // Car's current mileage - target mileage
    let daysDifference: Int?    // Days until due date

    // Status can be determined from these properties:
    // - Overdue if mileageDifference < 0 or daysDifference < 0
    // - Due soon if 0 <= daysDifference <= 7 or 0 <= mileageDifference <= 100
    // - Scheduled if daysDifference > 7 and mileageDifference > 100
}
```

**Current sorting logic:**
1. Overdue records (negative mileageDifference or past date)
2. Records with mileage triggers (sorted by mileageDifference ascending)
3. Records with date triggers (sorted by date ascending)
4. Records without triggers (sorted by createdAt)

---

## Implementation Plan

### Phase 1: Add FilterChip to EVChargingTracker

**Task 1.1: Copy FilterChip Component**
- Copy `FilterChip.swift` from Journey Wallet to EVChargingTracker
- Location: `EVChargingTracker/EVChargingTracker/Common/FilterChip.swift`
- Keep identical implementation to ensure consistency

**File structure:**
```
EVChargingTracker/
  EVChargingTracker/
    Common/
      FilterChip.swift  (NEW)
    Shared/
      FilterButtonsView.swift (KEEP - for now)
```

---

### Phase 2: Refactor Expenses Screen Filters

**Goal:** Replace full-width FilterButtonsView with compact FilterChip components, and split the grouped "Repair/maintenance" filter into separate filters for "Maintenance" and "Repair".

**Task 2.1: Create ExpensesFilter Enum**
- Create `ExpensesFilter` enum with 1:1 mapping to ExpenseType categories
- Each ExpenseType gets its own filter button (no grouping)
- Location: `EVChargingTracker/BusinessLogic/Models/ExpenseModels.swift` (append to file)

```swift
enum ExpensesFilter: String, CaseIterable {
    case all
    case charging
    case maintenance
    case repair
    case carwash
    case other

    var displayName: String {
        switch self {
        case .all: return L("expense.filter.all")
        case .charging: return L("expense.filter.charging")
        case .maintenance: return L("expense.filter.maintenance")
        case .repair: return L("expense.filter.repair")
        case .carwash: return L("expense.filter.carwash")
        case .other: return L("expense.filter.other")
        }
    }

    var expenseTypes: [ExpenseType] {
        switch self {
        case .all: return ExpenseType.allCases
        case .charging: return [.charging]
        case .maintenance: return [.maintenance]
        case .repair: return [.repair]
        case .carwash: return [.carwash]
        case .other: return [.other]
        }
    }
}
// Note: Unlike current implementation where "Repair/maintenance" is grouped,
// this creates separate filters for each ExpenseType
```

**Task 2.2: Update ExpensesViewModel**
- Replace `filterButtons: [FilterButtonItem]` with `selectedFilter: ExpensesFilter`
- Update `applyFilters()` logic to use enum
- Remove manual FilterButtonItem array initialization

**Changes to `ExpensesViewModel`:**
```swift
class ExpensesViewModel: ObservableObject, IExpenseView {
    @Published var expenses: [Expense] = []
    @Published var selectedFilter: ExpensesFilter = .all  // CHANGED
    @Published var currentPage: Int = 1
    @Published var totalRecords: Int = 0
    @Published var totalPages: Int = 0
    @Published var selectedSortingOption: ExpensesSortingOption = .creationDate

    var totalCost: Double = 0.0
    var hasAnyExpense = false

    let pageSize: Int = 15

    // REMOVE: @Published var filterButtons: [FilterButtonItem] = []
    // REMOVE: private var _currentExpenseTypeFilters: [ExpenseType] = []

    init(...) {
        // REMOVE: filterButtons = [...] initialization
        loadSessions()
    }

    func loadSessions() {
        // Use selectedFilter.expenseTypes instead of _currentExpenseTypeFilters
        loadSessionsForCurrentPage()
    }

    private func loadSessionsForCurrentPage() -> Void {
        let car = self.reloadSelectedCarForExpenses()
        if let car = car, let carId = car.id {
            hasAnyExpense = (db.expensesRepository?.expensesCount(carId) ?? 0) > 0

            totalRecords = chargingSessionsRepository.getExpensesCount(
                carId: carId,
                expenseTypeFilters: selectedFilter.expenseTypes  // CHANGED
            )

            // Calculate pages and fetch data...
            expenses = chargingSessionsRepository.fetchCarSessionsPaginated(
                carId: carId,
                expenseTypeFilters: selectedFilter.expenseTypes,  // CHANGED
                page: currentPage,
                pageSize: pageSize,
                sortBy: selectedSortingOption
            )
            totalCost = getTotalCost()
        }
    }

    func getTotalCost() -> Double {
        guard let car = selectedCarForExpenses, let carId = car.id else {
            return 0
        }
        return chargingSessionsRepository.getTotalCost(
            carId: carId,
            expenseTypeFilters: selectedFilter.expenseTypes  // CHANGED
        )
    }
}
```

**Task 2.3: Update ExpensesView**
- Replace `FilterButtonsView` with horizontal ScrollView of FilterChips
- Update filter section to match Journey Wallet pattern

**Changes to `ExpensesView`:**
```swift
// REPLACE this section:
// FilterButtonsView(filterButtons: viewModel.filterButtons)
//     .padding(.bottom, 4)
//     .padding(.horizontal)

// WITH:
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 8) {
        ForEach(ExpensesFilter.allCases, id: \.self) { filter in
            FilterChip(
                title: filter.displayName,
                isSelected: viewModel.selectedFilter == filter
            ) {
                viewModel.selectedFilter = filter
                viewModel.loadSessions()
            }
        }
    }
}
.padding(.horizontal)
.padding(.vertical, 4)

// UPDATE sorting selector position (move below filters)
```

**Task 2.4: Add Localization Keys**
- Add new localization keys for expense filters
- Update all language files (English, German, Russian, Turkish, Kazakh, Ukrainian)

**Required keys:**
```
expense.filter.all
expense.filter.charging
expense.filter.maintenance
expense.filter.repair
expense.filter.carwash
expense.filter.other
```

**Task 2.5: (Optional) Deprecate FilterButtonsView**
- Once Expenses is migrated and tested, consider deprecating `FilterButtonsView`
- Keep temporarily if other parts of the app use it
- Add `@available(*, deprecated)` annotation

---

### Phase 3: Add Filters to Planned Maintenance Screen

**Task 3.1: Create PlannedMaintenanceFilter Enum**
- Create filter enum for planned maintenance records
- Location: `EVChargingTracker/BusinessLogic/Models/PlannedMaintenance.swift` (append to file)

```swift
enum PlannedMaintenanceFilter: String, CaseIterable {
    case all
    case overdue
    case dueSoon
    case scheduled
    case byMileage
    case byDate

    var displayName: String {
        switch self {
        case .all: return L("maintenance.filter.all")
        case .overdue: return L("maintenance.filter.overdue")
        case .dueSoon: return L("maintenance.filter.due_soon")
        case .scheduled: return L("maintenance.filter.scheduled")
        case .byMileage: return L("maintenance.filter.by_mileage")
        case .byDate: return L("maintenance.filter.by_date")
        }
    }
}
```

**Task 3.2: Update PlanedMaintenanceViewModel**
- Add `selectedFilter` property
- Add `filteredRecords` computed property
- Add helper methods for filter logic

**Changes to `PlanedMaintenanceViewModel`:**
```swift
class PlanedMaintenanceViewModel: ObservableObject {
    @Published var maintenanceRecords: [PlannedMaintenanceItem] = []
    @Published var selectedFilter: PlannedMaintenanceFilter = .all  // NEW

    // ... existing properties ...

    func loadData() -> Void {
        let selectedCar = self.reloadSelectedCarForExpenses()
        if (selectedCar == nil) {
            return
        }

        let now = Date()
        var records = maintenanceRepository.getAllRecords(carId: selectedCar!.id!).map { dbRecord in
            PlannedMaintenanceItem(maintenance: dbRecord, car: selectedCar, now: now)
        }

        records.sort()
        DispatchQueue.main.async {
            self.maintenanceRecords = records
        }
    }

    // NEW: Filtered records property
    var filteredRecords: [PlannedMaintenanceItem] {
        switch selectedFilter {
        case .all:
            return maintenanceRecords
        case .overdue:
            return maintenanceRecords.filter { isOverdue($0) }
        case .dueSoon:
            return maintenanceRecords.filter { isDueSoon($0) }
        case .scheduled:
            return maintenanceRecords.filter { isScheduled($0) }
        case .byMileage:
            return maintenanceRecords.filter { $0.mileageDifference != nil }
        case .byDate:
            return maintenanceRecords.filter { $0.daysDifference != nil }
        }
    }

    // NEW: Helper methods
    private func isOverdue(_ record: PlannedMaintenanceItem) -> Bool {
        // Overdue if date is in the past OR mileage has been exceeded
        if let days = record.daysDifference, days < 0 {
            return true
        }
        if let mileage = record.mileageDifference, mileage < 0 {
            return true
        }
        return false
    }

    private func isDueSoon(_ record: PlannedMaintenanceItem) -> Bool {
        // Due soon within next 7 days OR within 100 km
        if let days = record.daysDifference, days >= 0 && days <= 7 {
            return true
        }
        if let mileage = record.mileageDifference, mileage >= 0 && mileage <= 100 {
            return true
        }
        return false
    }

    private func isScheduled(_ record: PlannedMaintenanceItem) -> Bool {
        // Scheduled for future (beyond 7 days AND beyond 100 km)
        let daysOk = record.daysDifference == nil || record.daysDifference! > 7
        let mileageOk = record.mileageDifference == nil || record.mileageDifference! > 100
        return daysOk && mileageOk
    }

    // ... existing methods ...
}
```

**Task 3.3: Update PlanedMaintenanceView**
- Add filter section at the top of the view
- Use horizontal ScrollView with FilterChips
- Update `maintenanceListView` to use `filteredRecords` instead of `maintenanceRecords`

**Changes to `PlanedMaintenanceView`:**
```swift
struct PlanedMaintenanceView: View {
    // ... existing properties ...

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.filteredRecords.isEmpty {  // CHANGED
                            EmptyStateView(selectedCar: viewModel.selectedCarForExpenses)
                        } else if viewModel.selectedCarForExpenses != nil {
                            // NEW: Filter section
                            filterSection

                            VStack(spacing: 12) {
                                Text(L("For deleting record, please swipe left"))
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .padding(.horizontal)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                maintenanceListView
                            }

                            Spacer()
                                .frame(height: 80)
                        }
                    }
                    .padding(.vertical)
                }
                // ... rest of body ...
            }
            floatingAddButton
        }
    }

    // NEW: Filter section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PlannedMaintenanceFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                        // filteredRecords is computed, no reload needed
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var maintenanceListView: some View {
        List {
            ForEach(viewModel.filteredRecords) { record in  // CHANGED
                PlannedMaintenanceItemView(
                    selectedCar: viewModel.selectedCarForExpenses!,
                    record: record
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        // ... existing swipe actions ...
                    } label: {
                        Label(L("Delete"), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(minHeight: CGFloat(viewModel.filteredRecords.count) * 140)  // CHANGED
    }

    // ... rest of view ...
}
```

**Task 3.4: Update EmptyStateView Logic**
- Update empty state to consider filtered records
- Show different message when filtering results in empty list

```swift
// In PlanedMaintenanceView:
if viewModel.filteredRecords.isEmpty {
    if viewModel.maintenanceRecords.isEmpty {
        EmptyStateView(
            selectedCar: viewModel.selectedCarForExpenses,
            message: viewModel.selectedFilter == .all
                ? L("No maintenance records yet")
                : L("No records match the selected filter")
        )
    } else {
        // Show empty state for filter results
        EmptyStateView(
            selectedCar: viewModel.selectedCarForExpenses,
            message: L("No records match the selected filter")
        )
    }
}
```

**Task 3.5: Add Localization Keys**
- Add new localization keys for maintenance filters
- Update all language files

**Required keys:**
```
maintenance.filter.all
maintenance.filter.overdue
maintenance.filter.due_soon
maintenance.filter.scheduled
maintenance.filter.by_mileage
maintenance.filter.by_date
```

---

### Phase 4: Testing and Validation

**Task 4.1: Unit Tests**
- Write unit tests for filter logic
- Test filter enum cases and displayName
- Test expense filtering logic
- Test maintenance filtering logic

**Test cases for ExpensesFilter:**
```swift
struct ExpensesFilterTests {
    // Test that all expense types are returned for .all
    // Test that single type is returned for specific filters
    // Test that filters don't crash with empty arrays
}
```

**Test cases for PlannedMaintenanceFilter:**
```swift
struct PlannedMaintenanceFilterTests {
    // Test overdue detection (past dates, exceeded mileage)
    // Test due soon detection (within 7 days, within 100 km)
    // Test scheduled detection (beyond thresholds)
    // Test byMileage filter (only shows records with mileage)
    // Test byDate filter (only shows records with dates)
}
```

**Task 4.2: UI Testing**
- Manual testing on actual device/simulator
- Test filter selection and deselection
- Test horizontal scrolling with multiple filters
- Test filter persistence across screen navigation
- Test empty states for each filter

**Task 4.3: Accessibility Testing**
- Test VoiceOver navigation
- Ensure filter chips are properly announced
- Verify color contrast for selected/unselected states
- Test Dynamic Type sizing

**Task 4.4: Cross-Platform Testing**
- Test on iOS 18.0+
- Test in light mode and dark mode
- Test with different device sizes (iPhone, iPad)
- Test with different text sizes

---

### Phase 5: Documentation and Cleanup

**Task 5.1: Update CLAUDE.md**
- Document the new FilterChip component usage
- Add filter pattern to code conventions
- Update expenses and planned maintenance sections

**Task 5.2: Update User Documentation**
- Document new filter functionality in user-facing docs
- Add screenshots showing filter UI

**Task 5.3: Code Cleanup**
- Remove deprecated FilterButtonsView if no longer used
- Remove old filter-related code from ViewModels
- Ensure no unused imports or variables

**Task 5.4: Performance Review**
- Profile filter operations for performance
- Ensure filtered arrays don't cause memory issues
- Optimize if filtering large datasets

---

## Implementation Priority

### High Priority
1. **Phase 1:** Add FilterChip component to EVChargingTracker
2. **Phase 2:** Refactor Expenses screen filters (critical UX improvement)
3. **Phase 3.1-3.3:** Add filters to Planned Maintenance screen (new functionality)

### Medium Priority
4. **Phase 4:** Testing and validation
5. **Phase 3.4:** Update EmptyStateView logic for filters

### Low Priority
6. **Phase 5:** Documentation and cleanup
7. Deprecate FilterButtonsView (only if fully replaced)

---

## Benefits of This Implementation

### User Experience
- **Consistency:** Matches Journey Wallet's proven filter pattern
- **Scalability:** Easy to add new filters in future
- **Clear feedback:** Orange highlight makes selection obvious
- **Accessibility:** Better VoiceOver support with standard buttons
- **Space-efficient:** Pills take less vertical space than full-width buttons
- **Improved granularity:** Separate "Maintenance" and "Repair" filters for more precise filtering

### Developer Experience
- **Type-safe:** Enums prevent invalid filter values
- **Maintainable:** Clear separation of concerns
- **Testable:** Filter logic is easy to unit test
- **Reusable:** FilterChip can be used across the app
- **Consistent code:** Follows established patterns

### Code Quality
- **DRY principle:** No duplication of filter logic
- **SOLID principles:** Single responsibility for filters
- **Localization:** All strings properly localized
- **Performance:** Computed properties avoid unnecessary recalculations

---

## Risks and Mitigation

### Risk 1: Breaking Changes in ExpensesViewModel
**Mitigation:**
- Carefully review all usages of `loadSessions()` method
- Ensure backward compatibility if method signature changes
- Test thoroughly after refactoring

### Risk 2: Performance Issues with Large Datasets
**Mitigation:**
- Profile filter operations with large datasets
- Consider lazy evaluation if needed
- Add pagination for very large datasets

### Risk 3: Inconsistent UI if FilterButtonsView Not Deprecated
**Mitigation:**
- Document which screens use which filter component
- Create migration plan for remaining screens
- Eventually migrate all screens to FilterChip

### Risk 4: Localization Key Conflicts
**Mitigation:**
- Use unique keys for each filter type
- Verify all language files include new keys
- Test app in all supported languages

---

## Summary

This plan brings EVChargingTracker's filter implementation in line with Journey Wallet's proven pattern:

1. **Expenses Screen:** Migrates from full-width buttons to compact pill-shaped chips
   - **Important:** Splits grouped "Repair/maintenance" filter into separate "Maintenance" and "Repair" filters
   - Result: 6 filter buttons instead of 4 (All, Charging, Maintenance, Repair, Carwash, Other)
2. **Planned Maintenance Screen:** Adds new filtering capability (previously had none)
3. **Code Consistency:** Both apps will use the same FilterChip component
4. **Better UX:** More filters visible, easier selection, clear visual feedback, horizontal scrolling
5. **Type Safety:** Enum-based filters prevent bugs
6. **Maintainability:** Cleaner code, easier to extend

The implementation is structured in phases to allow incremental development and testing, with high-priority items completed first to deliver user value quickly.
