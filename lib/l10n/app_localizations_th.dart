// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'ResPOS - ระบบ POS ร้านบุฟเฟ่ต์';

  @override
  String get tableSelection => 'เลือกโต๊ะ';

  @override
  String get settings => 'ตั้งค่า';

  @override
  String get reports => 'รายงาน';

  @override
  String get shift => 'กะทำงาน';

  @override
  String get menu => 'เมนู';

  @override
  String get printers => 'เครื่องพิมพ์';

  @override
  String get layout => 'เลย์เอาท์';

  @override
  String get refresh => 'รีเฟรช';

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get all => 'ทั้งหมด';

  @override
  String get fieldRequired => 'กรุณาระบุข้อมูล';

  @override
  String get saveAndConnect => 'บันทึกและเชื่อมต่อ';

  @override
  String get saveConfiguration => 'บันทึกการตั้งค่า';

  @override
  String get comingSoon => 'เร็วๆ นี้';

  @override
  String get openShift => 'เปิดกะ';

  @override
  String get closeShift => 'ปิดกะ';

  @override
  String get shiftOpen => 'กะเปิดอยู่';

  @override
  String get shiftClosed => 'กะปิดแล้ว';

  @override
  String get startingCash => 'เงินสดเริ่มต้น';

  @override
  String get expectedCash => 'เงินสดที่คาดหวัง';

  @override
  String get totalSalesCash => 'ยอดขายรวม (เงินสด)';

  @override
  String get readyToStartNewShift => 'พร้อมเริ่มกะใหม่';

  @override
  String get shiftOpenedSuccessfully => 'เปิดกะสำเร็จแล้ว';

  @override
  String get shiftClosedSuccessfully => 'ปิดกะสำเร็จแล้ว';

  @override
  String get shiftManagement => 'จัดการกะ';

  @override
  String startedAt(Object time) {
    return 'เริ่มเมื่อ $time';
  }

  @override
  String get startingCashFloat => 'เงินทอนเริ่มต้น';

  @override
  String get openShiftAction => 'เปิดกะ';

  @override
  String get closeShiftAction => 'ปิดกะ';

  @override
  String get salesReports => 'รายงานยอดขาย';

  @override
  String get totalSales => 'ยอดขายรวม';

  @override
  String get totalOrders => 'จำนวนออเดอร์';

  @override
  String get revenueTrend => 'แนวโน้มรายได้';

  @override
  String get recentTransactions => 'รายการล่าสุด';

  @override
  String get noRecentSales => 'ไม่มียอดขายล่าสุด';

  @override
  String get revenueChartVisualization => 'กราฟแสดงรายได้';

  @override
  String get items => 'รายการ';

  @override
  String get order => 'ออเดอร์';

  @override
  String get table => 'โต๊ะ';

  @override
  String get currentOrder => 'รายการปัจจุบัน';

  @override
  String get buffetHeadcount => 'จำนวนลูกค้าบุฟเฟ่ต์';

  @override
  String tierPricePerson(Object price) {
    return 'ราคา: $price / ท่าน';
  }

  @override
  String get shopInformation => 'ข้อมูลร้าน';

  @override
  String get shopDetails => 'รายละเอียดร้าน';

  @override
  String get notConfigured => 'ยังไม่ได้ตั้งค่า';

  @override
  String get paymentSettings => 'ตั้งค่าการชำระเงิน';

  @override
  String get promptPay => 'พร้อมเพย์';

  @override
  String get appearance => 'รูปลักษณ์';

  @override
  String get theme => 'ธีม';

  @override
  String get dark => 'มืด';

  @override
  String get light => 'สว่าง';

  @override
  String get system => 'ระบบ';

  @override
  String get currency => 'สกุลเงิน';

  @override
  String get thaiBaht => 'บาท (฿)';

  @override
  String get usDollar => 'ดอลลาร์ (\$)';

  @override
  String get language => 'ภาษา';

  @override
  String get thai => 'ไทย';

  @override
  String get english => 'English';

  @override
  String get posPreferences => 'ตั้งค่า POS';

  @override
  String get taxRate => 'อัตราภาษี (%)';

  @override
  String get serviceCharge => 'ค่าบริการ (%)';

  @override
  String get general => 'ทั่วไป';

  @override
  String get soundEffects => 'เสียงเอฟเฟกต์';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get appInfo => 'ข้อมูลแอป';

  @override
  String get aboutResPOS => 'เกี่ยวกับ ResPOS';

  @override
  String get shopName => 'ชื่อร้าน';

  @override
  String get enterShopName => 'ป้อนชื่อร้าน';

  @override
  String get address => 'ที่อยู่';

  @override
  String get enterAddress => 'ป้อนที่อยู่';

  @override
  String get telephone => 'โทรศัพท์';

  @override
  String get enterPhoneNumber => 'ป้อนเบอร์โทรศัพท์';

  @override
  String get operatingHours => 'เวลาทำการ';

  @override
  String get open => 'เปิด';

  @override
  String get close => 'ปิด';

  @override
  String get addLogo => 'เพิ่มโลโก้';

  @override
  String get shopInfoSavedSuccessfully => 'บันทึกข้อมูลร้านสำเร็จแล้ว';

  @override
  String get promptPayId => 'รหัสพร้อมเพย์';

  @override
  String get promptPayIdHint => 'เช่น 0812345678';

  @override
  String get qrCodeImage => 'รูป QR Code';

  @override
  String get tapToUploadQr => 'แตะเพื่ออัพโหลด QR';

  @override
  String get uploadYourPromptPayQr => 'อัพโหลดรูป QR พร้อมเพย์ของคุณ';

  @override
  String get paymentSettingsSavedSuccessfully => 'บันทึกตั้งค่าการชำระเงินสำเร็จแล้ว';

  @override
  String get save => 'บันทึก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get add => 'เพิ่ม';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get back => 'กลับ';

  @override
  String get available => 'ว่าง';

  @override
  String get occupied => 'มีลูกค้า';

  @override
  String get cleaning => 'กำลังทำความสะอาด';

  @override
  String get openTable => 'เปิดโต๊ะ';

  @override
  String get selectGuestsAndTier => 'เลือกจำนวนลูกค้าและระดับบุฟเฟ่ต์';

  @override
  String get checkout => 'เช็คเอาท์';

  @override
  String get addItems => 'เพิ่มรายการ';

  @override
  String get adults => 'ผู้ใหญ่';

  @override
  String get children => 'เด็ก';

  @override
  String get buffetTier => 'ระดับบุฟเฟ่ต์';

  @override
  String get total => 'รวม';

  @override
  String get subtotal => 'ยอดรวมย่อย';

  @override
  String get cash => 'เงินสด';

  @override
  String get promptPayPayment => 'พร้อมเพย์';

  @override
  String get amountReceived => 'จำนวนเงินที่รับ';

  @override
  String get change => 'เงินทอน';

  @override
  String get paymentComplete => 'ชำระเงินเรียบร้อย';

  @override
  String get orderSummary => 'สรุปออเดอร์';

  @override
  String get buffetCharge => 'ค่าบุฟเฟ่ต์';

  @override
  String get paymentMethod => 'วิธีการชำระเงิน';

  @override
  String get cashPayment => 'ชำระเงินสด';

  @override
  String get amountToPay => 'ยอดชำระ';

  @override
  String get enterAmount => 'ระบุจำนวนเงิน';

  @override
  String get completeOrder => 'ยืนยันการชำระเงิน';

  @override
  String get scanToPay => 'สแกนเพื่อจ่าย';

  @override
  String get qrCode => 'QR Code';

  @override
  String cleaningTable(Object name) {
    return 'กำลังทำความสะอาด $name';
  }

  @override
  String get tableBeingCleaned => 'โต๊ะกำลังอยู่ในระหว่างการทำความสะอาด';

  @override
  String get finishCleaning => 'เสร็จสิ้น';

  @override
  String tableNowAvailable(Object name) {
    return '$name ว่างแล้ว';
  }

  @override
  String get menuManagement => 'จัดการเมนู';

  @override
  String get categories => 'หมวดหมู่';

  @override
  String get menuItems => 'รายการอาหาร';

  @override
  String get addCategory => 'เพิ่มหมวดหมู่';

  @override
  String get addItem => 'เพิ่มรายการ';

  @override
  String get itemName => 'ชื่อรายการ';

  @override
  String get extraCharge => 'ชาร์จเพิ่ม';

  @override
  String get noCategories => 'ไม่มีหมวดหมู่';

  @override
  String get noItems => 'ไม่มีรายการ';

  @override
  String get searchItems => 'ค้นหาเมนู...';

  @override
  String get newItem => 'เพิ่มเมนูใหม่';

  @override
  String get editItem => 'แก้ไขเมนู';

  @override
  String get selectCategory => 'เลือกหมวดหมู่';

  @override
  String get categoryLabel => 'หมวดหมู่';

  @override
  String get codeSku => 'รหัส / SKU';

  @override
  String get namesSection => 'ชื่อเมนู';

  @override
  String get englishName => 'ชื่อภาษาอังกฤษ';

  @override
  String get thaiName => 'ชื่อภาษาไทย';

  @override
  String get chineseName => 'ชื่อภาษาจีน';

  @override
  String get pricingDetails => 'ราคาและรายละเอียด';

  @override
  String get price => 'ราคา';

  @override
  String get buffetIncluded => 'รวมในบุฟเฟ่ต์';

  @override
  String get priceZeroForBuffet => 'ราคา 0 สำหรับบุฟเฟต์';

  @override
  String get description => 'รายละเอียดเพิ่มเติม';

  @override
  String get availableActive => 'สถานะพร้อมขาย';

  @override
  String get markAsSoldOut => 'ปิดเพื่อแสดงว่า \"หมด\"';

  @override
  String get addImage => 'รูปภาพ';

  @override
  String get pleaseSelectCategory => 'กรุณาเลือกหมวดหมู่';

  @override
  String get pleaseEnterName => 'กรุณาระบุชื่อเมนู';

  @override
  String get newCategory => 'เพิ่มหมวดหมู่ใหม่';

  @override
  String get editCategory => 'แก้ไขหมวดหมู่';

  @override
  String get categoryName => 'ชื่อหมวดหมู่';

  @override
  String get bluetoothPrinter => 'เครื่องพิมพ์บลูทูธ';

  @override
  String get scanForDevices => 'ค้นหาอุปกรณ์';

  @override
  String get connect => 'เชื่อมต่อ';

  @override
  String get disconnect => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get testPrint => 'ทดสอบพิมพ์';

  @override
  String get connected => 'เชื่อมต่อแล้ว';

  @override
  String get notConnected => 'ไม่ได้เชื่อมต่อ';

  @override
  String get scanning => 'กำลังค้นหา...';

  @override
  String get noDevicesFound => 'ไม่พบอุปกรณ์';

  @override
  String get printerSettings => 'ตั้งค่าเครื่องพิมพ์';

  @override
  String get networkWifi => 'เครือข่าย / WiFi';

  @override
  String get usb => 'USB';

  @override
  String get networkConfiguration => 'ตั้งค่าเครือข่าย';

  @override
  String get ipAddress => 'IP Address';

  @override
  String get port => 'Port';

  @override
  String get printerNetworkInfo => 'เครื่องพิมพ์ความร้อนส่วนใหญ่ใช้ Port 9100 สำหรับระบบเครือข่าย ตรวจสอบให้แน่ใจว่าอุปกรณ์เชื่อมต่อ WiFi เดียวกัน';

  @override
  String get usbPrintingComingSoon => 'ระบบพิมพ์ผ่าน USB จะเปิดใช้งานเร็วๆ นี้';

  @override
  String get unknownDevice => 'อุปกรณ์ไม่ระบุชื่อ';

  @override
  String get noAddress => 'ไม่มีที่อยู่';

  @override
  String get refreshList => 'รีเฟรชรายการ';

  @override
  String get scanForNew => 'สแกนหาอุปกรณ์ใหม่';

  @override
  String get stopScan => 'หยุดสแกน';

  @override
  String get pairedDevices => 'อุปกรณ์ที่จับคู่แล้ว';

  @override
  String get nearbyDevices => 'อุปกรณ์ใกล้เคียง';

  @override
  String get tapToPairConnect => 'แตะเพื่อจับคู่และเชื่อมต่อ';

  @override
  String get notPaired => 'ยังไม่ได้จับคู่';

  @override
  String get scanningForDevices => 'กำลังสแกนหาอุปกรณ์ใกล้เคียง...';

  @override
  String get noPrintersFound => 'ไม่พบเครื่องพิมพ์';

  @override
  String get howToConnectPrinter => 'วิธีเชื่อมต่อเครื่องพิมพ์:';

  @override
  String get putPrinterPairingMode => 'เปิดโหมดจับคู่ของเครื่องพิมพ์ (ดูคู่มือเครื่องพิมพ์)';

  @override
  String get openBluetoothSettings => 'เปิดการตั้งค่าบลูทูธของ Android';

  @override
  String get findAndPair => 'ค้นหาและจับคู่ชื่อเครื่องพิมพ์ของคุณ';

  @override
  String get returnAndRefresh => 'กลับมาที่แอปนี้และแตะรีเฟรช';

  @override
  String get openBluetoothSettingsButton => 'เปิดการตั้งค่าบลูทูธ';

  @override
  String get connectionFailed => 'เชื่อมต่อไม่สำเร็จ';

  @override
  String get devicePairedButNotConnected => 'อุปกรณ์จับคู่แล้วแต่เชื่อมต่อไม่สำเร็จ กรุณาลองเชื่อมต่ออีกครั้ง';

  @override
  String get connectionFailedDetails => 'การเชื่อมต่อล้มเหลว กรุณาตรวจสอบ:\n1. เครื่องพิมพ์เปิดอยู่และอยู่ในระยะ\n2. คุณยอมรับคำขอจับคู่หากปรากฏ\n3. ลองเชื่อมต่ออีกครั้ง';

  @override
  String get bluetoothPermissionsRequired => 'ต้องการสิทธิ์บลูทูธ กรุณาอนุญาตสิทธิ์ในการตั้งค่าแอป';

  @override
  String get bluetoothNotAvailable => 'บลูทูธไม่พร้อมใช้งาน กรุณาเปิดบลูทูธบนอุปกรณ์ของคุณ';

  @override
  String get errorLoadingDevices => 'เกิดข้อผิดพลาดในการโหลดอุปกรณ์';

  @override
  String get availablePrinters => 'เครื่องพิมพ์ที่มี';

  @override
  String get refreshPairedDevices => 'รีเฟรชอุปกรณ์ที่จับคู่แล้ว';

  @override
  String get apiSettings => 'ตั้งค่า API';

  @override
  String get endpointsConfig => 'ตั้งค่า Endpoints';

  @override
  String get updateMenuEndpoint => 'Endpoint อัปเกรดเมนู';

  @override
  String get getOrdersEndpoint => 'Endpoint รับออเดอร์';

  @override
  String get apiKeyOptional => 'API Key (เลือกใส่)';

  @override
  String get apiSettingsSaved => 'บันทึกตั้งค่า API แล้ว';

  @override
  String get receiptDesigner => 'ออกแบบใบเสร็จ';

  @override
  String get setupLayout => 'ตั้งค่าเลย์เอาท์';

  @override
  String get customersTitle => 'ลูกค้าสมาชิก';

  @override
  String get addCustomer => 'เพิ่มลูกค้า';

  @override
  String get editCustomer => 'แก้ไขข้อมูลลูกค้า';

  @override
  String get deleteCustomer => 'ลบลูกค้า';

  @override
  String get searchCustomerHint => 'ค้นหาจากชื่อหรือเบอร์โทร...';

  @override
  String get noCustomersFound => 'ไม่พบข้อมูลลูกค้า';

  @override
  String get customerAdded => 'เพิ่มลูกค้าเรียบร้อย';

  @override
  String get customerUpdated => 'อัปเดตข้อมูลลูกค้าเรียบร้อย';

  @override
  String get customerDeleted => 'ลบลูกค้าเรียบร้อย';

  @override
  String get nameRequired => 'กรุณาระบุชื่อ';

  @override
  String get tableLayoutTitle => 'ผังโต๊ะ';

  @override
  String get addTable => 'เพิ่มโต๊ะ';

  @override
  String get deleteTable => 'ลบโต๊ะ';

  @override
  String get tableNameLabel => 'ชื่อโต๊ะ';

  @override
  String get tableAdded => 'เพิ่มโต๊ะเรียบร้อย';

  @override
  String get tableDeleted => 'ลบโต๊ะเรียบร้อย';

  @override
  String get buffetTiersTitle => 'แพ็กเกจบุฟเฟ่ต์';

  @override
  String get addBuffetTier => 'เพิ่มแพ็กเกจ';

  @override
  String get editBuffetTier => 'แก้ไขแพ็กเกจ';

  @override
  String get tierAdded => 'เพิ่มแพ็กเกจเรียบร้อย';

  @override
  String get tierUpdated => 'อัปเดตแพ็กเกจเรียบร้อย';

  @override
  String get descriptionOptional => 'รายละเอียด (ไม่บังคับ)';

  @override
  String get activeStatus => 'เปิดใช้งาน';

  @override
  String get inactiveStatus => 'ปิดใช้งาน';

  @override
  String get promotionsTitle => 'โปรโมชั่น';

  @override
  String get addPromotion => 'เพิ่มโปรโมชั่น';

  @override
  String get editPromotion => 'แก้ไขโปรโมชั่น';

  @override
  String get discountValue => 'มูลค่าส่วนลด';

  @override
  String get promotionAdded => 'เพิ่มโปรโมชั่นเรียบร้อย';

  @override
  String get promotionUpdated => 'อัปเดตโปรโมชั่นเรียบร้อย';

  @override
  String get promotionDeleted => 'ลบโปรโมชั่นเรียบร้อย';

  @override
  String get visualReceiptDesignerTitle => 'ออกแบบใบเสร็จ';

  @override
  String get saveLayout => 'บันทึกเลย์เอาต์';

  @override
  String get layoutSaved => 'บันทึกเลย์เอาต์เรียบร้อย!';

  @override
  String errorSavingLayout(Object error) {
    return 'เกิดข้อผิดพลาดในการบันทึก: $error';
  }

  @override
  String get componentsTitle => 'ส่วนประกอบ';

  @override
  String get propertiesTitle => 'คุณสมบัติ';

  @override
  String get selectElementToEdit => 'เลือกรายการเพื่อแก้ไข';

  @override
  String get alignmentLabel => 'การจัดวาง';

  @override
  String get textContentLabel => 'ข้อความ';

  @override
  String get fontSizeLabel => 'ขนาดตัวอักษร';

  @override
  String get heightLabel => 'ความสูง';

  @override
  String get dropHere => 'วางที่นี่';

  @override
  String get headerComponent => 'หัวบิล';

  @override
  String get textComponent => 'ข้อความ';

  @override
  String get dividerComponent => 'เส้นคั่น';

  @override
  String get spacerComponent => 'ช่องว่าง';

  @override
  String get imageComponent => 'รูปภาพ';

  @override
  String get orderListComponent => 'รายการอาหาร';

  @override
  String get totalsComponent => 'ยอดรวม';

  @override
  String get dynamicData => 'ข้อมูลไดนามิก';

  @override
  String get nameLabel => 'ชื่อ';

  @override
  String get phoneLabel => 'เบอร์โทร';

  @override
  String get emailLabel => 'อีเมล';

  @override
  String get deleteTier => 'ลบแพ็กเกจ';

  @override
  String get tierDeleted => 'ลบแพ็กเกจเรียบร้อย';

  @override
  String get noBuffetTiers => 'ไม่มีรายการแพ็กเกจ';

  @override
  String get deletePromotion => 'ลบโปรโมชั่น';

  @override
  String get noPromotionsFound => 'ไม่พบโปรโมชั่น';

  @override
  String get selectPromotion => 'เลือกโปรโมชั่น';

  @override
  String get discountLabel => 'ส่วนลด';

  @override
  String get subtotalLabel => 'รวมย่อย';

  @override
  String get removePromotion => 'นำโปรโมชั่นออก';

  @override
  String get apply => 'ใช้';

  @override
  String get printReceipt => 'พิมพ์ใบเสร็จ';

  @override
  String get edcPayment => 'ชำระเงินผ่าน EDC';

  @override
  String get edcTerminal => 'เครื่อง EDC';

  @override
  String get enableEdcPayment => 'เปิดใช้งานการชำระด้วยบัตร';

  @override
  String get edcDescription => 'รับชำระเงินผ่านเครื่องรูดบัตร EDC';

  @override
  String get terminalType => 'ประเภทเครื่อง';

  @override
  String get connectionType => 'ประเภทการเชื่อมต่อ';

  @override
  String get terminalAddress => 'ที่อยู่เครื่อง';

  @override
  String get addressHintSerial => 'เช่น COM1 หรือ /dev/tty.usbserial';

  @override
  String get addressHintNetwork => 'เช่น 192.168.1.100:8000';

  @override
  String get terminalId => 'รหัสเครื่อง (Terminal ID)';

  @override
  String get merchantId => 'รหัสร้านค้า (Merchant ID)';

  @override
  String get testConnection => 'ทดสอบการเชื่อมต่อ';

  @override
  String get connectionSuccess => 'เชื่อมต่อสำเร็จ';

  @override
  String get waitingForCard => 'กรุณาเสียบหรือแตะบัตร';

  @override
  String get processingPayment => 'กำลังดำเนินการชำระเงิน...';

  @override
  String get paymentApproved => 'ชำระเงินสำเร็จ';

  @override
  String get paymentDeclined => 'บัตรถูกปฏิเสธ';

  @override
  String get cardPayment => 'บัตร (EDC)';

  @override
  String get shiftClosedError => 'กะปิดอยู่ กรุณาเปิดกะก่อนทำรายการ';

  @override
  String get loyaltyPointsRule => 'กติกาแต้มสะสม';

  @override
  String get loyaltyPointsRulePrompt => 'ยอดใช้จ่ายกี่บาท (THB) ได้รับ 1 แต้ม?';

  @override
  String get bahtAmount => 'จำนวนเงิน (บาท)';

  @override
  String get pointsRuleUpdated => 'อัปเดตการตั้งค่าแต้มแล้ว';

  @override
  String get selectCustomer => 'เลือกลูกค้า';

  @override
  String get layoutDesigner => 'ออกแบบแปลนร้าน';

  @override
  String get tools => 'เครื่องมือ';

  @override
  String get properties => 'คุณสมบัติ';

  @override
  String get width => 'ความกว้าง';

  @override
  String get height => 'ความสูง';

  @override
  String get rotation => 'การหมุน';

  @override
  String get duplicate => 'ทำซ้ำ';

  @override
  String get toFront => 'ย้ายไปข้างหน้า';

  @override
  String get toBack => 'ย้ายไปข้างหลัง';

  @override
  String get icon => 'ไอคอน';

  @override
  String get fillColor => 'สีพื้นหลัง';

  @override
  String get wall => 'กำแพง';

  @override
  String get plant => 'ต้นไม้';

  @override
  String get door => 'ประตู';

  @override
  String get chair => 'เก้าอี้';

  @override
  String get couch => 'โซฟา';

  @override
  String get tv => 'ทีวี';

  @override
  String get music => 'เครื่องเสียง';

  @override
  String get wifi => 'ไวไฟ';

  @override
  String get fan => 'พัดลม';

  @override
  String get fire => 'ถังดับเพลิง';

  @override
  String get restroom => 'ห้องน้ำ';

  @override
  String get kitchen => 'ครัว';

  @override
  String get bar => 'บาร์';

  @override
  String get cashier => 'แคชเชียร์';

  @override
  String get none => 'ไม่มี';

  @override
  String get object => 'วัตถุ';

  @override
  String get selectItem => 'เลือกรายการ';

  @override
  String get receiptBuffetCharges => 'ค่าบุฟเฟต์';

  @override
  String get receiptExtraItems => 'รายการเพิ่มเติม';

  @override
  String get receiptBuffetSubtotal => 'รวมค่าบุฟเฟต์';

  @override
  String get receiptExtrasSubtotal => 'รวมค่าเพิ่มเติม';

  @override
  String get receiptGrandTotal => 'ยอดรวมทั้งหมด';

  @override
  String get receiptThankYou => 'ขอบคุณที่มาใช้บริการ!';

  @override
  String get receiptAdult => 'ผู้ใหญ่';

  @override
  String get receiptChild => 'เด็ก';

  @override
  String get receiptTable => 'โต๊ะ';

  @override
  String get receiptOrder => 'ออเดอร์';

  @override
  String get receiptDate => 'วันที่';

  @override
  String get receiptTime => 'เวลา';

  @override
  String get receiptGuests => 'จำนวนลูกค้า';

  @override
  String get receiptPayment => 'การชำระเงิน';

  @override
  String get backupRestore => 'สำรองและกู้คืน';

  @override
  String get backupDescription => 'สำรองฐานข้อมูล รูปภาพ และการตั้งค่า เพื่อย้ายไปเครื่องอื่นหรือกู้คืนในภายหลัง';

  @override
  String get createBackup => 'สร้างข้อมูลสำรอง';

  @override
  String get restoreBackup => 'กู้คืนข้อมูล';

  @override
  String get backupIncludes => 'ข้อมูลสำรองประกอบด้วย:';

  @override
  String get database => 'ฐานข้อมูล (ออเดอร์, เมนู, โต๊ะ ฯลฯ)';

  @override
  String get menuImages => 'รูปภาพเมนู';

  @override
  String get appSettings => 'การตั้งค่าแอป';

  @override
  String get receiptLayouts => 'รูปแบบใบเสร็จ';

  @override
  String get createBackupNow => 'สร้างข้อมูลสำรองเดี๋ยวนี้';

  @override
  String get selectBackupFile => 'เลือกไฟล์สำรองเพื่อกู้คืน:';

  @override
  String get browseFiles => 'เรียกดูไฟล์';

  @override
  String get availableBackups => 'ข้อมูลสำรองที่มี';

  @override
  String get backupWarning => 'การกู้คืนข้อมูลจะแทนที่ข้อมูลปัจจุบันทั้งหมด กรุณาสำรองข้อมูลปัจจุบันก่อนหากต้องการ';

  @override
  String get qrCodeOrdering => 'สั่งอาหารผ่าน QR Code';

  @override
  String get qrOrderingEnabled => 'ลูกค้าสามารถสแกน QR เพื่อสั่งอาหาร';

  @override
  String get qrOrderingDisabled => 'ปิดการสั่งอาหารผ่าน QR';

  @override
  String get qrUrlConfig => 'ตั้งค่า URL สำหรับ QR';

  @override
  String get qrBaseUrl => 'URL หลัก';

  @override
  String get qrUrlStructure => 'โครงสร้าง URL';

  @override
  String get openTableQrDesc => 'QR เปิดโต๊ะ';

  @override
  String get menuPageDesc => 'หน้าเมนู';

  @override
  String get storeInfo => 'ข้อมูลร้าน';

  @override
  String get shopLogo => 'โลโก้ร้าน';

  @override
  String get shopAddress => 'ที่อยู่ร้าน';

  @override
  String get shopTel => 'เบอร์โทรร้าน';

  @override
  String get completed => 'เสร็จสมบูรณ์';

  @override
  String get receiptPrintedSuccessfully => 'พิมพ์ใบเสร็จสำเร็จ';

  @override
  String get errorOccurred => 'เกิดข้อผิดพลาด';

  @override
  String get earned => 'ได้รับ';

  @override
  String get points => 'คะแนน';

  @override
  String get insufficientFunds => 'เงินไม่พอ! กรุณาใส่อย่างน้อย';

  @override
  String get takeAway => 'สั่งกลับบ้าน';

  @override
  String get takeAwayDescription => 'ออเดอร์สำหรับลูกค้าที่ไม่ได้นั่งทานในร้าน';

  @override
  String get newTakeAwayOrder => 'สั่งกลับบ้านใหม่';

  @override
  String get takeAwayComingSoon => 'ฟีเจอร์สั่งกลับบ้านเร็วๆ นี้!';

  @override
  String get todayOrders => 'ออเดอร์วันนี้';

  @override
  String get pendingOrders => 'รอดำเนินการ';

  @override
  String get completedOrders => 'เสร็จสมบูรณ์';

  @override
  String get orderItems => 'รายการสั่ง';

  @override
  String get syncAllData => 'ซิงค์ข้อมูลทั้งหมด';

  @override
  String get syncAllDataDesc => 'ส่งข้อมูล POS ทั้งหมดไปยังเซิร์ฟเวอร์ (สำหรับการตั้งค่าครั้งแรก)';

  @override
  String get sendAllData => 'ส่งข้อมูลทั้งหมด';

  @override
  String get syncing => 'กำลังซิงค์...';

  @override
  String get buffetTiers => 'แพ็กเกจบุฟเฟ่ต์';

  @override
  String get tables => 'โต๊ะ';

  @override
  String get apiNotEnabled => 'กรุณาเปิดใช้งาน API และบันทึกการตั้งค่าก่อน';

  @override
  String get apiConnectionFailed => 'เชื่อมต่อไม่สำเร็จ กรุณาตรวจสอบ URL และ API key';

  @override
  String get apiSyncSuccess => 'ซิงค์ข้อมูลทั้งหมดสำเร็จ!';

  @override
  String get apiSyncPartialFail => 'บางรายการซิงค์ไม่สำเร็จ';

  @override
  String get printToKitchen => 'พิมพ์ส่งครัว';

  @override
  String get served => 'เสิร์ฟแล้ว';

  @override
  String get printSuccess => 'ส่งไปยังเครื่องพิมพ์แล้ว';

  @override
  String get orderServed => 'รับออเดอร์แล้ว';

  @override
  String get noPendingOrders => 'ไม่มีออเดอร์รอดำเนินการ';

  @override
  String get moveTable => 'ย้ายโต๊ะ';

  @override
  String get cancelTable => 'ยกเลิกโต๊ะ';

  @override
  String get confirmCancelTable => 'คุณแน่ใจหรือไม่ว่าต้องการยกเลิกโต๊ะนี้? ออเดอร์จะถูกล้าง';

  @override
  String get selectDestinationTable => 'เลือกโต๊ะปลายทาง';

  @override
  String get tableMoved => 'ย้ายโต๊ะเรียบร้อย';

  @override
  String get tableCancelled => 'ยกเลิกโต๊ะเรียบร้อย';
}
