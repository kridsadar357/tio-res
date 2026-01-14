# Bluetooth Thermal Printer Integration

This document describes the Bluetooth thermal printer functionality in ResPOS.

## Overview

ResPOS integrates Bluetooth thermal printer support to automatically print receipts after order checkout. The system uses ESC/POS commands to generate professional receipts with order details, buffet charges, and extra items.

## Features

- **Bluetooth Device Management**: Scan, connect, and disconnect from Bluetooth thermal printers
- **Automatic Reconnection**: Remembers last used printer and auto-reconnects
- **Receipt Generation**: Beautiful formatted receipts with ESC/POS commands
- **Test Print Functionality**: Verify printer setup with test receipt
- **Error Handling**: Graceful error messages when printing fails
- **Permission Management**: Automatic Android Bluetooth permission requests

## Architecture

### Components

1. **BluetoothPrinterService** (`lib/services/bluetooth_printer_service.dart`)
   - Singleton service managing printer connections
   - Handles device scanning, connection, and printing
   - Persists last used printer via SharedPreferences

2. **BluetoothPrinterScreen** (`lib/screens/bluetooth_printer_screen.dart`)
   - UI for managing Bluetooth printer connections
   - Device list with connection status
   - Test print functionality

3. **Checkout Integration**
   - Both `checkout_screen.dart` and `checkout_screen_simple.dart`
   - Auto-prompts to print receipt after successful checkout
   - Handles print errors gracefully

## Dependencies

```yaml
# Bluetooth Thermal Printer
blue_thermal_printer: ^1.2.0
esc_pos_utils_plus: ^2.1.0
permission_handler: ^11.1.0
shared_preferences: ^2.2.2
```

## Setup Instructions

### 1. Pair Printer with Android Device

1. Enable Bluetooth on your Android tablet
2. Go to Settings → Bluetooth
3. Put your thermal printer in pairing mode (refer to printer manual)
4. Select your printer from the list and complete pairing
5. Note the printer's name and MAC address

### 2. Configure Printer in App

1. Open ResPOS on your tablet
2. Tap the **Printer icon** in any screen's app bar:
   - Table Selection screen
   - POS screen (when viewing a table)
   - POS Main screen (in order panel header)
3. The Bluetooth Printer screen will open
4. Tap the **Refresh icon** to scan for paired devices
5. Tap **Connect** next to your thermal printer
6. Once connected, tap **Test Print** to verify

### 3. Verify Printer Settings

The printer is configured with the following defaults:

```dart
static const int _printerWidth = 58;  // 58mm thermal printer width
static const int _defaultAdultPrice = 25;  // Default adult buffet price
static const int _defaultChildPrice = 15;  // Default child buffet price
```

If you're using an 80mm printer, update the `_printerWidth` constant to `80`.

## Usage

### Printing Receipts After Checkout

1. Complete an order checkout (CASH or QR payment)
2. After successful payment, a dialog appears: "Print Receipt?"
3. Tap **Print Receipt** to print
4. The receipt will include:
   - Restaurant name and address
   - Table and order number
   - Date and time
   - Buffet charges breakdown
   - Extra items list
   - Grand total
   - Payment method

### Managing Printer Connection

**From the Bluetooth Printer Screen:**

- **Refresh**: Scan for paired Bluetooth devices
- **Connect**: Connect to a printer from the list
- **Disconnect**: Disconnect from current printer
- **Test Print**: Print a test receipt to verify printer is working

**Connection Status:**

- **Green**: Connected and ready
- **Grey**: Not connected
- The app automatically reuses the last connected printer

### Troubleshooting

**Printer not appearing in device list:**

1. Ensure printer is paired with the tablet (Android Bluetooth settings)
2. Put printer in pairing mode if needed
3. Restart the app
4. Check if Bluetooth is enabled on the tablet

**Print job fails:**

1. Check printer is powered on and has paper
2. Verify printer is connected (green status)
3. Try Test Print to verify printer works
4. Disconnect and reconnect the printer
5. Check printer battery/power source

**Permission denied errors (Android):**

1. Go to Settings → Apps → ResPOS → Permissions
2. Enable Bluetooth permissions:
   - Bluetooth
   - Bluetooth Scan
   - Bluetooth Connect
3. Restart the app

**Receipt format issues:**

1. Check printer width setting (58mm vs 80mm)
2. Verify printer paper is loaded correctly
3. Try Test Print to isolate the issue

## Receipt Format

The generated receipt includes:

```
RESTAURANT NAME
123 Main St, City
======================================
Table:  T1        Order:  #123
Date:   2024-01-12
Time:   14:30
======================================
BUFFET CHARGES
Adult Buffet (2x)          $50.00
Child Buffet (1x)          $15.00
Buffet Subtotal            $65.00
======================================
EXTRA ITEMS
Item #123            x1    $5.00
Item #456            x2    $12.00
Extras Subtotal            $17.00
======================================
BUFFET SUBTOTAL           $65.00
EXTRAS SUBTOTAL           $17.00
======================================
GRAND TOTAL              $82.00
======================================
Payment Method:            CASH

Thank you for dining with us!
======================================
Powered by ResPOS
```

## API Reference

### BluetoothPrinterService

**Singleton Instance:**
```dart
final printerService = BluetoothPrinterService();
```

**Methods:**

```dart
// Initialize the service (call once at app startup)
await printerService.init();

// Scan for paired Bluetooth devices
List<BluetoothDevice>? devices = await printerService.scanDevices();

// Connect to a specific device
bool success = await printerService.connect(device);

// Disconnect from current printer
await printerService.disconnect();

// Print a receipt
await printerService.printReceipt(
  table: tableModel,
  order: order,
  orderItems: orderItems,
  restaurantName: 'My Restaurant',
  restaurantAddress: '123 Main St',
);

// Print a test receipt
await printerService.printTestReceipt();

// Check connection status
bool isConnected = await printerService.checkConnection();

// Get connection status
bool isConnected = printerService.isConnected;
BluetoothDevice? device = printerService.connectedDevice;
```

## Printer Compatibility

The implementation has been tested with common 58mm thermal printers that support:

- Standard ESC/POS commands
- Bluetooth connectivity
- Basic text formatting (bold, double-width/height)
- Line feeding and cutting commands

**Known Compatible Printers:**

- Generic 58mm Bluetooth Thermal Printers
- Most printers with ESC/POS support

**To test with a new printer:**

1. Pair with your Android device
2. Use the Test Print feature
3. Verify receipt format
4. Adjust `_printerWidth` if needed

## Customization

### Restaurant Information

To customize the restaurant name and address on receipts, modify the `printReceipt` call:

```dart
await printerService.printReceipt(
  table: tableModel,
  order: order,
  orderItems: orderItems,
  restaurantName: 'Your Restaurant Name',
  restaurantAddress: 'Your Address, City, Country',
);
```

### Buffet Pricing

To change default buffet prices, modify the constants in `BluetoothPrinterService`:

```dart
static const int _defaultAdultPrice = 30;  // Adult buffet price
static const int _defaultChildPrice = 20;  // Child buffet price
```

### Printer Width

For 80mm printers, update the width:

```dart
static const int _printerWidth = 80;  // 80mm thermal printer width
```

### Receipt Styling

The receipt generation uses `esc_pos_utils_plus` with `PosStyles`:

```dart
generator.text(
  'Bold Text',
  styles: const PosStyles(bold: true),
);
```

See `esc_pos_utils_plus` documentation for more styling options.

## Security Considerations

- **Bluetooth Pairing**: Always pair printer in a secure environment
- **Data Privacy**: Receipts contain order information; dispose of receipts properly
- **Access Control**: Only staff with app access can manage printer connections

## Best Practices

1. **Test Regularly**: Print test receipts before peak hours
2. **Paper Management**: Keep spare paper rolls available
3. **Connection Check**: Verify printer connection before service
4. **Error Monitoring**: Watch for print errors and address promptly
5. **Backup Plan**: Have a manual receipt process ready if printer fails

## Future Enhancements

Potential improvements:

- [ ] Support for 80mm printers
- [ ] QR code on receipts for digital verification
- [ ] Logo/image printing support
- [ ] Multiple printer profiles
- [ ] Print queue management
- [ ] Receipt preview before printing
- [ ] Print history and logging
- [ ] Custom receipt templates

## Support

For issues or questions about Bluetooth printer integration:

1. Check this documentation
2. Verify printer compatibility
3. Review app logs for error messages
4. Test with the Test Print feature
5. Refer to printer manufacturer documentation

## License

This printer integration is part of ResPOS and follows the same license terms.
