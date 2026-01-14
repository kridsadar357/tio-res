# ResPOS Project Structure

## File Overview

This document provides a quick reference to all files created for the Buffet Restaurant POS System.

```
ResPOS/
├── pubspec.yaml                          # Flutter dependencies and configuration
├── README.md                             # Comprehensive project documentation
├── PROJECT_STRUCTURE.md                   # This file
│
├── lib/
│   ├── main.dart                         # App entry point with Screen Ratio initialization
│   │
│   ├── models/                           # Data models for all database tables
│   │   ├── table_model.dart             # Table entity with status management
│   │   ├── menu_category.dart           # Menu category entity
│   │   ├── menu_item.dart              # Menu item entity with price/image support
│   │   ├── order.dart                  # Order/session entity with buffet logic
│   │   ├── order_item.dart             # Order item entity with price snapshot
│   │   └── transaction.dart            # Transaction entity for payment history
│   │
│   ├── services/                         # Business logic and data access
│   │   ├── database_helper.dart         # SQLite CRUD operations (Singleton)
│   │   └── image_storage_service.dart   # Local image storage management
│   │
│   ├── screens/                          # UI screens
│   │   ├── table_selection_screen.dart  # Table grid with status indicators
│   │   ├── pos_screen.dart              # Two-pane Master-Detail POS interface
│   │   ├── checkout_dialog.dart         # Payment processing dialog
│   │   └── add_menu_item_screen.dart   # Add/edit menu items with images
│   │
│   └── utils/                            # Utility classes
│       └── screen_util.dart             # Responsive design and scaling utilities
│
└── assets/
    └── images/                          # Static assets (empty - using dynamic images)
```

## Key Features by File

### pubspec.yaml
- Flutter and Dart SDK constraints
- Dependencies: flutter_riverpod, sqflite, image_picker, path_provider, flutter_screenutil
- Assets directory configuration

### main.dart
- Database initialization
- ScreenUtil initialization
- Material Design 3 theme configuration
- Typography scaling
- Responsive color schemes

### models/table_model.dart
- Table entity with id, name, status, currentOrderId
- Status helpers: isAvailable, isOccupied, isCleaning
- statusText getter for display
- copyWith method for immutability

### models/menu_category.dart
- Category entity with id, name, iconPath
- Simple, lightweight model

### models/menu_item.dart
- Menu item with price, imagePath, isBuffetIncluded
- hasExtraCharge helper (price > 0)
- formattedPrice for display
- hasImage helper

### models/order.dart
- Order/session entity with headcount tracking
- buffetTierPrice (snapshot at opening time)
- Core buffet logic: totalHeadcount, buffetCharge
- Duration calculation
- Status helpers

### models/order_item.dart
- Order item with price snapshot
- totalPrice = quantity * priceAtMoment
- hasExtraCharge helper
- Formatted display strings

### models/transaction.dart
- Transaction entity for payment history
- Payment method helpers (isCash, isQR)
- Formatted amounts
- DateTime conversion

### services/database_helper.dart
- Singleton pattern
- Complete CRUD operations for all tables
- Buffet logic implementation (openTable, calculateOrderTotal)
- Transaction support (checkoutOrder)
- Statistics and reporting methods
- Index creation for performance

### services/image_storage_service.dart
- Singleton pattern
- Pick from camera or gallery
- Save to app documents directory
- File path management
- Delete and replace operations
- Storage statistics

### screens/table_selection_screen.dart
- Grid view of tables
- Color-coded status cards
- Open table dialog with:
  - Adult/child counters
  - Buffet tier selection
- Refresh functionality
- Responsive grid columns

### screens/pos_screen.dart
- Two-pane Master-Detail layout (60/40)
- Left pane:
  - Category filter chips
  - Menu items grid
  - Image display with placeholders
  - Add to order on tap
- Right pane:
  - Order summary
  - Order items list with remove buttons
  - Buffet info section
  - Running total
  - Checkout button

### screens/checkout_dialog.dart
- Order summary breakdown
  - Buffet charge calculation
  - Extra items total
- Payment method selection:
  - Cash: Amount input + change calculation
  - QR: Placeholder for payment gateway
- Order completion with status update

### screens/add_menu_item_screen.dart
- Form with validation:
  - Name (required)
  - Category (dropdown)
  - Price (number input)
  - Is Buffet Included (checkbox)
- Image picker:
  - Camera or Gallery selection
  - Image preview
  - Remove option
- Async image storage
- Create or update mode

### utils/screen_util.dart
- Screen ratio calculation
- Scaling factors for fonts and widgets
- Pre-calculated common values
- Extensions on double/int for easy scaling
- Screen type detection

## Database Schema Summary

### Tables
1. **tables** - Restaurant tables with status
2. **menu_categories** - Item categorization
3. **menu_items** - Menu items with pricing
4. **orders** - Dining sessions with buffet data
5. **order_items** - Items ordered to tables
6. **transactions** - Payment history

### Key Relationships
- tables.current_order_id → orders.id
- orders.table_id → tables.id
- menu_items.category_id → menu_categories.id
- order_items.order_id → orders.id
- order_items.menu_item_id → menu_items.id
- transactions.order_id → orders.id

## Buffet Logic Implementation

### Pricing Formula
```
Total = (Adults + Children) × BuffetTierPrice + Σ(ExtraItems × Price)
```

### Price Snapshotting
- `orders.buffet_tier_price`: Tier price when table opened
- `order_items.price_at_moment`: Item price when added to order
- Prevents historical data changes from affecting records

### Status Flow
```
Available (0) → Occupied (1) → Cleaning (2) → Available (0)
```

## Image Storage Strategy

### Why NOT BLOBs in SQLite?
- Database bloat
- Performance degradation
- Backup complexity

### Approach
1. Store images in `/app_data/menu_images/`
2. Store relative path in database
3. Load with `Image.file(File(path))`
4. Automatic cleanup on deletion

## Responsive Design

### Breakpoints
- Mobile: < 600px width
- Small Tablet: 600-900px
- Medium Tablet: 900-1200px
- Large Tablet: > 1200px

### Scaling
- Width-based scaling for horizontal elements
- Height-based scaling for vertical elements
- Font scaling as average of both
- Touch-friendly targets

## Code Quality

### Design Patterns
- Singleton (DatabaseHelper, ImageStorageService)
- Provider (Riverpod for state management)
- Repository (DatabaseHelper abstracts SQLite)
- Builder (FutureBuilder, LayoutBuilder)

### Best Practices
- Null safety throughout
- Immutability with copyWith
- Separation of concerns
- Error handling with user feedback
- Loading states
- Form validation

## Testing Checklist

- [ ] Table opening with various headcounts
- [ ] Adding buffet items (price = 0)
- [ ] Adding extra items (price > 0)
- [ ] Removing items from order
- [ ] Cash payment with exact amount
- [ ] Cash payment with change
- [ ] QR payment (placeholder)
- [ ] Menu item creation with image
- [ ] Menu item creation without image
- [ ] Image from camera
- [ ] Image from gallery
- [ ] Table status transitions
- [ ] Order completion and table cleanup

## Dependencies Version (as of creation)

```yaml
flutter_riverpod: ^2.4.9
sqflite: ^2.3.0
path: ^1.8.3
image_picker: ^1.0.5
path_provider: ^2.1.1
flutter_screenutil: ^5.9.0
```

## Build Instructions

```bash
# Install dependencies
flutter pub get

# Run on device
flutter run

# Build APK
flutter build apk

# Build App Bundle
flutter build appbundle
```

## Permissions Required (Android)

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Minimum Requirements

- Android 5.0 (API level 21) or higher
- 7" or larger tablet screen
- 2GB RAM recommended
- 500MB free storage

---

**Total Files Created: 17**
**Lines of Code: ~3000+**
**Database Tables: 6**
**Screens: 4**
**Models: 6**
**Services: 2**
**Utilities: 1**
