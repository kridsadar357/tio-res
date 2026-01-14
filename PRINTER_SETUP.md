# Bluetooth Printer Setup Guide

## Prerequisites

Before using the Bluetooth printer functionality, you need to install the dependencies:

```bash
cd /Users/mac/develop/ResPOS
flutter pub get
```

This will download the required packages:
- `blue_thermal_printer`: Bluetooth printer connectivity
- `esc_pos_utils_plus`: Receipt formatting
- `permission_handler`: Android permissions
- `shared_preferences`: Store printer preferences

## Running the App

After running `flutter pub get`, the Bluetooth printer types will be available and the linter errors will be resolved.

### Build and Run

```bash
flutter run
```

### On Android Device

The app will automatically request necessary Bluetooth permissions on first run:
- Bluetooth Scan
- Bluetooth Connect
- Bluetooth
- Bluetooth Advertise

## Quick Setup Checklist

- [ ] Run `flutter pub get` to install dependencies
- [ ] Pair thermal printer with Android tablet (Bluetooth settings)
- [ ] Open ResPOS app
- [ ] Tap printer icon (top right corner)
- [ **] Scan for devices (refresh button)
- [ **] Connect to your printer
- [ **] Test print to verify

## Troubleshooting Linter Errors

If you see these linter errors:
```
The name 'BluetoothDevice' isn't a type
Undefined class 'BluetoothDevice'
```

**Solution**: Run `flutter pub get` to fetch the dependencies.

## Common Issues

### Package not found errors

```bash
# Clear cache and reinstall
flutter clean
flutter pub get
flutter run
```

### Bluetooth permissions denied

Go to Android Settings → Apps → ResPOS → Permissions and enable all Bluetooth permissions.

### Printer not found in device list

1. Ensure printer is paired with tablet (Android Bluetooth settings)
2. Make sure Bluetooth is enabled on tablet
3. Put printer in pairing mode if needed
4. Restart the app

## Testing the Implementation

1. **Test Printer Connection**
   - Open BluetoothPrinterScreen
   - Connect to your printer
   - Tap "Test Print"
   - Verify receipt prints correctly

2. **Test Checkout Printing**
   - Open a table and complete an order
   - Process payment (Cash or QR)
   - Confirm print receipt when prompted
   - Verify complete receipt prints

3. **Test Auto-Reconnect**
   - Connect to a printer
   - Close and reopen app
   - Verify printer stays connected automatically

## Supported Printer Features

- ✅ Connect/Disconnect
- ✅ Print receipts with order details
- ✅ Test print functionality
- ✅ Auto-reconnect to last printer
- ✅ 58mm thermal printer support
- ✅ ESC/POS commands for formatting

## Next Steps

After setup is complete:
1. Read the detailed documentation in `lib/services/PRINTER_README.md`
2. Configure restaurant name and address in printer service
3. Adjust buffet prices if needed
4. Test with real orders
