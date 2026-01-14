# ResPOS - Buffet Restaurant POS System

A complete offline-first Point of Sale (POS) system designed specifically for buffet-style restaurants, built with Flutter for Android Tablet devices.

## 🎯 Project Overview

ResPOS is a restaurant management application optimized for buffet dining with the following key features:

- **Offline-First Architecture**: Uses SQLite for local data storage - no internet connection required during operation
- **Table Management**: Visual grid view with color-coded status indicators (Available/Occupied/Cleaning)
- **Buffet Logic**: Handles both headcount charges (by tier) and à la carte items (alcohol, special items)
- **Digital Menu**: Categorized menu items with image support
- **Ordering System**: Two-pane Master-Detail layout optimized for tablet use
- **Multiple Payment Methods**: Cash with change calculation, QR Code (placeholder for integration)
- **Responsive Design**: Material Design 3 with screen ratio adaptation for various tablet sizes

## 📱 Screens

### 1. Table Selection Screen
- Grid view of all restaurant tables
- Color-coded status:
  - 🟢 Green: Available
  - 🔴 Red: Occupied/Eating
  - 🟡 Yellow: Cleaning
- Tap available tables to open with headcount and buffet tier selection
- Navigate to occupied tables for ordering

### 2. POS Screen (Main Ordering Interface)
Two-pane Master-Detail layout:

**Left Pane (60%):**
- Category filter chips at the top
- Menu items grid with images
- Tap items to add to order
- Price indicators (0 for buffet items, actual price for extra items)

**Right Pane (40%):**
- Current order summary
- Ordered items with quantity controls
- Buffet headcount information
- Running total
- Checkout button

### 3. Checkout Dialog
- Order summary breakdown:
  - Buffet Charge: (Headcount × Tier Price)
  - Extra Items: Sum of à la carte items
- Payment method selection: Cash or QR Code
- For Cash: Input received amount, auto-calculate change
- QR Code placeholder for payment gateway integration

### 4. Add Menu Item Screen
- Form fields: Name, Category, Price, "Is Buffet Included" checkbox
- Image picker with Camera or Gallery options
- Image preview after selection
- Async image storage to local device directory
- Form validation

## 🗂️ Project Structure

```
lib/
├── main.dart                          # App entry point with screen ratio initialization
├── models/
│   ├── table_model.dart              # Table data model
│   ├── menu_category.dart            # Menu category data model
│   ├── menu_item.dart                # Menu item data model
│   ├── order.dart                    # Order (session) data model
│   ├── order_item.dart               # Order item data model
│   └── transaction.dart              # Transaction data model
├── services/
│   ├── database_helper.dart          # SQLite database operations (Singleton)
│   └── image_storage_service.dart    # Local image storage management
├── screens/
│   ├── table_selection_screen.dart   # Table grid view
│   ├── pos_screen.dart               # Main ordering interface
│   ├── checkout_dialog.dart          # Payment and checkout
│   └── add_menu_item_screen.dart     # Add/edit menu items with images
└── utils/
    └── screen_util.dart              # Responsive design utilities
```

## 💾 Database Schema

### Tables

**tables**
- `id` (Integer, PK)
- `table_name` (String)
- `status` (Integer: 0=Available, 1=Occupied, 2=Cleaning)
- `current_order_id` (Nullable Int)

**menu_categories**
- `id` (Integer, PK)
- `name` (String)
- `icon_path` (String)

**menu_items**
- `id` (Integer, PK)
- `name` (String)
- `category_id` (Integer, FK)
- `price` (Real: 0 for buffet, >0 for extra items)
- `image_path` (String, nullable)
- `is_buffet_included` (Boolean)

**orders** (sessions)
- `id` (Integer, PK)
- `table_id` (Integer, FK)
- `start_time` (Integer)
- `end_time` (Integer, nullable)
- `adult_headcount` (Integer)
- `child_headcount` (Integer)
- `buffet_tier_price` (Real) - Price at time of opening
- `total_amount` (Real)
- `payment_method` (String: 'CASH', 'QR')
- `status` (String: 'OPEN', 'COMPLETED', 'CANCELLED')

**order_items**
- `id` (Integer, PK)
- `order_id` (Integer, FK)
- `menu_item_id` (Integer, FK)
- `quantity` (Integer)
- `price_at_moment` (Real) - Snapshot price

**transactions**
- `id` (Integer, PK)
- `order_id` (Integer, FK)
- `total_amount` (Real)
- `payment_method` (String)
- `amount_received` (Real, nullable)
- `change_amount` (Real, nullable)
- `transaction_time` (Integer)

## 🎨 Design System

### Material Design 3
- Modern, clean, minimalist aesthetic
- Card widgets with subtle shadows
- Large, readable fonts for touch interfaces
- Deep orange as primary color

### Responsive Design
- **ScreenUtil**: Custom utility for screen ratio calculation
- **flutter_screenutil**: Additional responsive scaling
- Optimized for landscape tablet layouts
- Adaptive grid columns based on screen width

### Typography Scale
- Small: 12sp
- Normal: 14sp
- Medium: 16sp
- Large: 18sp
- X-Large: 20sp
- XX-Large: 24sp
- XXX-Large: 32sp

## 🔧 Tech Stack

- **Framework**: Flutter (Latest Stable)
- **Language**: Dart
- **State Management**: Riverpod
- **Database**: sqflite (SQLite)
- **Image Handling**: image_picker, path_provider
- **Responsive**: flutter_screenutil
- **Design**: Material Design 3

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extension
- Android Tablet (physical device) or Android Emulator

### Installation

1. **Clone the repository:**
```bash
git clone <repository-url>
cd ResPOS
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Run the app:**
```bash
flutter run
```

### Configuration

#### Adding Menu Items
1. Navigate to the menu management (feature coming soon)
2. Use the AddMenuItemScreen to add items
3. Select image from Camera or Gallery
4. Set price to 0.00 for buffet-included items
5. Set price > 0 for extra chargeable items

#### Setting Buffet Tiers
Edit the `buffetTiers` list in `table_selection_screen.dart`:
```dart
final List<BuffetTier> buffetTiers = [
  BuffetTier(name: 'Standard', price: 25.0),
  BuffetTier(name: 'Premium', price: 35.0),
  BuffetTier(name: 'VIP', price: 50.0),
];
```

## 💡 Usage Guide

### Opening a Table
1. From the Table Selection Screen, tap an available (green) table
2. Enter the number of adults and children
3. Select the appropriate buffet tier
4. Tap "Open Table"

### Adding Items to Order
1. Navigate to the POS Screen by tapping an occupied (red) table
2. Select a category from the chips at the top
3. Tap menu items to add them to the order
4. View order summary in the right pane
5. Use the remove button (trash icon) to remove items

### Processing Payment
1. Tap the "Checkout" button
2. Review the order summary
3. Select payment method (Cash or QR)
4. For Cash: Enter the amount received, system calculates change
5. For QR: Customer scans the QR code with their payment app
6. Tap "Complete Order"
7. Table moves to "Cleaning" status

### Marking Table Available Again
After checkout, tables automatically move to "Cleaning" status. A future feature will allow staff to mark them as "Available" manually.

## 📊 Buffet Logic Explained

Unlike standard retail POS systems, ResPOS handles two types of charges:

### 1. Headcount Charge (Buffet Price)
- Calculated when opening a table
- Formula: `(Adults + Children) × Tier Price`
- Example: 2 adults + 1 child at $25/tier = $75

### 2. À La Carte Charge (Extra Items)
- Items with price > 0 are added to this total
- Example: 2 bottles of wine at $20 each = $40

### Final Total
`Total = Buffet Charge + Extra Items Charge`

## 🖼️ Image Storage

Images are NOT stored as BLOBs in the database. Instead:

1. Images are saved to the app's documents directory
2. File path is stored in the database (e.g., `menu_images/item_123456789.jpg`)
3. Images are displayed using `Image.file(File(path))`

**Benefits:**
- Smaller database size
- Better performance
- Easier image management
- Prevents database bloat

## 🔒 Data Management

### Backup
The SQLite database is located at:
```
/data/data/com.example.respos/databases/respos.db
```

To backup, copy this file to external storage.

### Reset
Use the `clearAllData()` method in `DatabaseHelper` to reset the database.

### Image Management
- View total images count: `ImageStorageService().getImagesCount()`
- Get total storage used: `ImageStorageService().getTotalImagesSize()`
- Delete all images: `ImageStorageService().deleteAllImages()`

## 🔄 Future Enhancements

- [ ] Admin dashboard with analytics
- [ ] Receipt printing support
- [ ] QR code payment gateway integration
- [ ] Staff management and permissions
- [ ] Cloud sync for multi-device support
- [ ] Advanced reporting and export
- [ ] Customer loyalty program
- [ ] Reservation system integration

## 📝 Code Conventions

- **Clean Architecture**: Separated concerns (Models, Services, Screens, Utils)
- **Singleton Pattern**: DatabaseHelper and ImageStorageService
- **State Management**: Riverpod for reactive state
- **Null Safety**: Full null-safety compliance
- **Comments**: Complex logic documented with inline comments
- **Naming**: Descriptive variable and function names

## 🐛 Known Issues

- QR code payment is a placeholder (requires payment gateway integration)
- No direct way to mark cleaning tables as available (need to restart app)
- Menu items don't show actual names in order summary (shows item ID)

## 📄 License

This project is proprietary and confidential.

## 👥 Support

For issues or questions, please contact the development team.

---

**Built with ❤️ using Flutter**
