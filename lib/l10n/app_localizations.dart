import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th')
  ];

  /// No description provided for @appTitle.
  ///
  /// In th, this message translates to:
  /// **'ResPOS - ระบบ POS ร้านบุฟเฟ่ต์'**
  String get appTitle;

  /// No description provided for @tableSelection.
  ///
  /// In th, this message translates to:
  /// **'เลือกโต๊ะ'**
  String get tableSelection;

  /// No description provided for @settings.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่า'**
  String get settings;

  /// No description provided for @reports.
  ///
  /// In th, this message translates to:
  /// **'รายงาน'**
  String get reports;

  /// No description provided for @shift.
  ///
  /// In th, this message translates to:
  /// **'กะทำงาน'**
  String get shift;

  /// No description provided for @menu.
  ///
  /// In th, this message translates to:
  /// **'เมนู'**
  String get menu;

  /// No description provided for @printers.
  ///
  /// In th, this message translates to:
  /// **'เครื่องพิมพ์'**
  String get printers;

  /// No description provided for @layout.
  ///
  /// In th, this message translates to:
  /// **'เลย์เอาท์'**
  String get layout;

  /// No description provided for @refresh.
  ///
  /// In th, this message translates to:
  /// **'รีเฟรช'**
  String get refresh;

  /// No description provided for @about.
  ///
  /// In th, this message translates to:
  /// **'เกี่ยวกับ'**
  String get about;

  /// No description provided for @all.
  ///
  /// In th, this message translates to:
  /// **'ทั้งหมด'**
  String get all;

  /// No description provided for @fieldRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาระบุข้อมูล'**
  String get fieldRequired;

  /// No description provided for @saveAndConnect.
  ///
  /// In th, this message translates to:
  /// **'บันทึกและเชื่อมต่อ'**
  String get saveAndConnect;

  /// No description provided for @saveConfiguration.
  ///
  /// In th, this message translates to:
  /// **'บันทึกการตั้งค่า'**
  String get saveConfiguration;

  /// No description provided for @comingSoon.
  ///
  /// In th, this message translates to:
  /// **'เร็วๆ นี้'**
  String get comingSoon;

  /// No description provided for @openShift.
  ///
  /// In th, this message translates to:
  /// **'เปิดกะ'**
  String get openShift;

  /// No description provided for @closeShift.
  ///
  /// In th, this message translates to:
  /// **'ปิดกะ'**
  String get closeShift;

  /// No description provided for @shiftOpen.
  ///
  /// In th, this message translates to:
  /// **'กะเปิดอยู่'**
  String get shiftOpen;

  /// No description provided for @shiftClosed.
  ///
  /// In th, this message translates to:
  /// **'กะปิดแล้ว'**
  String get shiftClosed;

  /// No description provided for @startingCash.
  ///
  /// In th, this message translates to:
  /// **'เงินสดเริ่มต้น'**
  String get startingCash;

  /// No description provided for @expectedCash.
  ///
  /// In th, this message translates to:
  /// **'เงินสดที่คาดหวัง'**
  String get expectedCash;

  /// No description provided for @totalSalesCash.
  ///
  /// In th, this message translates to:
  /// **'ยอดขายรวม (เงินสด)'**
  String get totalSalesCash;

  /// No description provided for @readyToStartNewShift.
  ///
  /// In th, this message translates to:
  /// **'พร้อมเริ่มกะใหม่'**
  String get readyToStartNewShift;

  /// No description provided for @shiftOpenedSuccessfully.
  ///
  /// In th, this message translates to:
  /// **'เปิดกะสำเร็จแล้ว'**
  String get shiftOpenedSuccessfully;

  /// No description provided for @shiftClosedSuccessfully.
  ///
  /// In th, this message translates to:
  /// **'ปิดกะสำเร็จแล้ว'**
  String get shiftClosedSuccessfully;

  /// No description provided for @shiftManagement.
  ///
  /// In th, this message translates to:
  /// **'จัดการกะ'**
  String get shiftManagement;

  /// No description provided for @startedAt.
  ///
  /// In th, this message translates to:
  /// **'เริ่มเมื่อ {time}'**
  String startedAt(Object time);

  /// No description provided for @startingCashFloat.
  ///
  /// In th, this message translates to:
  /// **'เงินทอนเริ่มต้น'**
  String get startingCashFloat;

  /// No description provided for @openShiftAction.
  ///
  /// In th, this message translates to:
  /// **'เปิดกะ'**
  String get openShiftAction;

  /// No description provided for @closeShiftAction.
  ///
  /// In th, this message translates to:
  /// **'ปิดกะ'**
  String get closeShiftAction;

  /// No description provided for @salesReports.
  ///
  /// In th, this message translates to:
  /// **'รายงานยอดขาย'**
  String get salesReports;

  /// No description provided for @totalSales.
  ///
  /// In th, this message translates to:
  /// **'ยอดขายรวม'**
  String get totalSales;

  /// No description provided for @totalOrders.
  ///
  /// In th, this message translates to:
  /// **'จำนวนออเดอร์'**
  String get totalOrders;

  /// No description provided for @revenueTrend.
  ///
  /// In th, this message translates to:
  /// **'แนวโน้มรายได้'**
  String get revenueTrend;

  /// No description provided for @recentTransactions.
  ///
  /// In th, this message translates to:
  /// **'รายการล่าสุด'**
  String get recentTransactions;

  /// No description provided for @noRecentSales.
  ///
  /// In th, this message translates to:
  /// **'ไม่มียอดขายล่าสุด'**
  String get noRecentSales;

  /// No description provided for @revenueChartVisualization.
  ///
  /// In th, this message translates to:
  /// **'กราฟแสดงรายได้'**
  String get revenueChartVisualization;

  /// No description provided for @items.
  ///
  /// In th, this message translates to:
  /// **'รายการ'**
  String get items;

  /// No description provided for @order.
  ///
  /// In th, this message translates to:
  /// **'ออเดอร์'**
  String get order;

  /// No description provided for @table.
  ///
  /// In th, this message translates to:
  /// **'โต๊ะ'**
  String get table;

  /// No description provided for @currentOrder.
  ///
  /// In th, this message translates to:
  /// **'รายการปัจจุบัน'**
  String get currentOrder;

  /// No description provided for @buffetHeadcount.
  ///
  /// In th, this message translates to:
  /// **'จำนวนลูกค้าบุฟเฟ่ต์'**
  String get buffetHeadcount;

  /// No description provided for @tierPricePerson.
  ///
  /// In th, this message translates to:
  /// **'ราคา: {price} / ท่าน'**
  String tierPricePerson(Object price);

  /// No description provided for @shopInformation.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลร้าน'**
  String get shopInformation;

  /// No description provided for @shopDetails.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียดร้าน'**
  String get shopDetails;

  /// No description provided for @notConfigured.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ได้ตั้งค่า'**
  String get notConfigured;

  /// No description provided for @paymentSettings.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่าการชำระเงิน'**
  String get paymentSettings;

  /// No description provided for @promptPay.
  ///
  /// In th, this message translates to:
  /// **'พร้อมเพย์'**
  String get promptPay;

  /// No description provided for @appearance.
  ///
  /// In th, this message translates to:
  /// **'รูปลักษณ์'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In th, this message translates to:
  /// **'ธีม'**
  String get theme;

  /// No description provided for @dark.
  ///
  /// In th, this message translates to:
  /// **'มืด'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In th, this message translates to:
  /// **'สว่าง'**
  String get light;

  /// No description provided for @system.
  ///
  /// In th, this message translates to:
  /// **'ระบบ'**
  String get system;

  /// No description provided for @currency.
  ///
  /// In th, this message translates to:
  /// **'สกุลเงิน'**
  String get currency;

  /// No description provided for @thaiBaht.
  ///
  /// In th, this message translates to:
  /// **'บาท (฿)'**
  String get thaiBaht;

  /// No description provided for @usDollar.
  ///
  /// In th, this message translates to:
  /// **'ดอลลาร์ (\$)'**
  String get usDollar;

  /// No description provided for @language.
  ///
  /// In th, this message translates to:
  /// **'ภาษา'**
  String get language;

  /// No description provided for @thai.
  ///
  /// In th, this message translates to:
  /// **'ไทย'**
  String get thai;

  /// No description provided for @english.
  ///
  /// In th, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @posPreferences.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่า POS'**
  String get posPreferences;

  /// No description provided for @taxRate.
  ///
  /// In th, this message translates to:
  /// **'อัตราภาษี (%)'**
  String get taxRate;

  /// No description provided for @serviceCharge.
  ///
  /// In th, this message translates to:
  /// **'ค่าบริการ (%)'**
  String get serviceCharge;

  /// No description provided for @general.
  ///
  /// In th, this message translates to:
  /// **'ทั่วไป'**
  String get general;

  /// No description provided for @soundEffects.
  ///
  /// In th, this message translates to:
  /// **'เสียงเอฟเฟกต์'**
  String get soundEffects;

  /// No description provided for @notifications.
  ///
  /// In th, this message translates to:
  /// **'การแจ้งเตือน'**
  String get notifications;

  /// No description provided for @appInfo.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลแอป'**
  String get appInfo;

  /// No description provided for @aboutResPOS.
  ///
  /// In th, this message translates to:
  /// **'เกี่ยวกับ ResPOS'**
  String get aboutResPOS;

  /// No description provided for @shopName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อร้าน'**
  String get shopName;

  /// No description provided for @enterShopName.
  ///
  /// In th, this message translates to:
  /// **'ป้อนชื่อร้าน'**
  String get enterShopName;

  /// No description provided for @address.
  ///
  /// In th, this message translates to:
  /// **'ที่อยู่'**
  String get address;

  /// No description provided for @enterAddress.
  ///
  /// In th, this message translates to:
  /// **'ป้อนที่อยู่'**
  String get enterAddress;

  /// No description provided for @telephone.
  ///
  /// In th, this message translates to:
  /// **'โทรศัพท์'**
  String get telephone;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In th, this message translates to:
  /// **'ป้อนเบอร์โทรศัพท์'**
  String get enterPhoneNumber;

  /// No description provided for @operatingHours.
  ///
  /// In th, this message translates to:
  /// **'เวลาทำการ'**
  String get operatingHours;

  /// No description provided for @open.
  ///
  /// In th, this message translates to:
  /// **'เปิด'**
  String get open;

  /// No description provided for @close.
  ///
  /// In th, this message translates to:
  /// **'ปิด'**
  String get close;

  /// No description provided for @addLogo.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มโลโก้'**
  String get addLogo;

  /// No description provided for @shopInfoSavedSuccessfully.
  ///
  /// In th, this message translates to:
  /// **'บันทึกข้อมูลร้านสำเร็จแล้ว'**
  String get shopInfoSavedSuccessfully;

  /// No description provided for @promptPayId.
  ///
  /// In th, this message translates to:
  /// **'รหัสพร้อมเพย์'**
  String get promptPayId;

  /// No description provided for @promptPayIdHint.
  ///
  /// In th, this message translates to:
  /// **'เช่น 0812345678'**
  String get promptPayIdHint;

  /// No description provided for @qrCodeImage.
  ///
  /// In th, this message translates to:
  /// **'รูป QR Code'**
  String get qrCodeImage;

  /// No description provided for @tapToUploadQr.
  ///
  /// In th, this message translates to:
  /// **'แตะเพื่ออัพโหลด QR'**
  String get tapToUploadQr;

  /// No description provided for @uploadYourPromptPayQr.
  ///
  /// In th, this message translates to:
  /// **'อัพโหลดรูป QR พร้อมเพย์ของคุณ'**
  String get uploadYourPromptPayQr;

  /// No description provided for @paymentSettingsSavedSuccessfully.
  ///
  /// In th, this message translates to:
  /// **'บันทึกตั้งค่าการชำระเงินสำเร็จแล้ว'**
  String get paymentSettingsSavedSuccessfully;

  /// No description provided for @save.
  ///
  /// In th, this message translates to:
  /// **'บันทึก'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิก'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In th, this message translates to:
  /// **'ลบ'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In th, this message translates to:
  /// **'แก้ไข'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In th, this message translates to:
  /// **'เพิ่ม'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In th, this message translates to:
  /// **'ยืนยัน'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In th, this message translates to:
  /// **'กลับ'**
  String get back;

  /// No description provided for @available.
  ///
  /// In th, this message translates to:
  /// **'ว่าง'**
  String get available;

  /// No description provided for @occupied.
  ///
  /// In th, this message translates to:
  /// **'มีลูกค้า'**
  String get occupied;

  /// No description provided for @cleaning.
  ///
  /// In th, this message translates to:
  /// **'กำลังทำความสะอาด'**
  String get cleaning;

  /// No description provided for @openTable.
  ///
  /// In th, this message translates to:
  /// **'เปิดโต๊ะ'**
  String get openTable;

  /// No description provided for @selectGuestsAndTier.
  ///
  /// In th, this message translates to:
  /// **'เลือกจำนวนลูกค้าและระดับบุฟเฟ่ต์'**
  String get selectGuestsAndTier;

  /// No description provided for @checkout.
  ///
  /// In th, this message translates to:
  /// **'เช็คเอาท์'**
  String get checkout;

  /// No description provided for @addItems.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มรายการ'**
  String get addItems;

  /// No description provided for @adults.
  ///
  /// In th, this message translates to:
  /// **'ผู้ใหญ่'**
  String get adults;

  /// No description provided for @children.
  ///
  /// In th, this message translates to:
  /// **'เด็ก'**
  String get children;

  /// No description provided for @buffetTier.
  ///
  /// In th, this message translates to:
  /// **'ระดับบุฟเฟ่ต์'**
  String get buffetTier;

  /// No description provided for @total.
  ///
  /// In th, this message translates to:
  /// **'รวม'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In th, this message translates to:
  /// **'ยอดรวมย่อย'**
  String get subtotal;

  /// No description provided for @cash.
  ///
  /// In th, this message translates to:
  /// **'เงินสด'**
  String get cash;

  /// No description provided for @promptPayPayment.
  ///
  /// In th, this message translates to:
  /// **'พร้อมเพย์'**
  String get promptPayPayment;

  /// No description provided for @amountReceived.
  ///
  /// In th, this message translates to:
  /// **'จำนวนเงินที่รับ'**
  String get amountReceived;

  /// No description provided for @change.
  ///
  /// In th, this message translates to:
  /// **'เงินทอน'**
  String get change;

  /// No description provided for @paymentComplete.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินเรียบร้อย'**
  String get paymentComplete;

  /// No description provided for @orderSummary.
  ///
  /// In th, this message translates to:
  /// **'สรุปออเดอร์'**
  String get orderSummary;

  /// No description provided for @buffetCharge.
  ///
  /// In th, this message translates to:
  /// **'ค่าบุฟเฟ่ต์'**
  String get buffetCharge;

  /// No description provided for @paymentMethod.
  ///
  /// In th, this message translates to:
  /// **'วิธีการชำระเงิน'**
  String get paymentMethod;

  /// No description provided for @cashPayment.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินสด'**
  String get cashPayment;

  /// No description provided for @amountToPay.
  ///
  /// In th, this message translates to:
  /// **'ยอดชำระ'**
  String get amountToPay;

  /// No description provided for @enterAmount.
  ///
  /// In th, this message translates to:
  /// **'ระบุจำนวนเงิน'**
  String get enterAmount;

  /// No description provided for @completeOrder.
  ///
  /// In th, this message translates to:
  /// **'ยืนยันการชำระเงิน'**
  String get completeOrder;

  /// No description provided for @scanToPay.
  ///
  /// In th, this message translates to:
  /// **'สแกนเพื่อจ่าย'**
  String get scanToPay;

  /// No description provided for @qrCode.
  ///
  /// In th, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @cleaningTable.
  ///
  /// In th, this message translates to:
  /// **'กำลังทำความสะอาด {name}'**
  String cleaningTable(Object name);

  /// No description provided for @tableBeingCleaned.
  ///
  /// In th, this message translates to:
  /// **'โต๊ะกำลังอยู่ในระหว่างการทำความสะอาด'**
  String get tableBeingCleaned;

  /// No description provided for @finishCleaning.
  ///
  /// In th, this message translates to:
  /// **'เสร็จสิ้น'**
  String get finishCleaning;

  /// No description provided for @tableNowAvailable.
  ///
  /// In th, this message translates to:
  /// **'{name} ว่างแล้ว'**
  String tableNowAvailable(Object name);

  /// No description provided for @menuManagement.
  ///
  /// In th, this message translates to:
  /// **'จัดการเมนู'**
  String get menuManagement;

  /// No description provided for @categories.
  ///
  /// In th, this message translates to:
  /// **'หมวดหมู่'**
  String get categories;

  /// No description provided for @menuItems.
  ///
  /// In th, this message translates to:
  /// **'รายการอาหาร'**
  String get menuItems;

  /// No description provided for @addCategory.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มหมวดหมู่'**
  String get addCategory;

  /// No description provided for @addItem.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มรายการ'**
  String get addItem;

  /// No description provided for @itemName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อรายการ'**
  String get itemName;

  /// No description provided for @extraCharge.
  ///
  /// In th, this message translates to:
  /// **'ชาร์จเพิ่ม'**
  String get extraCharge;

  /// No description provided for @noCategories.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีหมวดหมู่'**
  String get noCategories;

  /// No description provided for @noItems.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีรายการ'**
  String get noItems;

  /// No description provided for @searchItems.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาเมนู...'**
  String get searchItems;

  /// No description provided for @newItem.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มเมนูใหม่'**
  String get newItem;

  /// No description provided for @editItem.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขเมนู'**
  String get editItem;

  /// No description provided for @selectCategory.
  ///
  /// In th, this message translates to:
  /// **'เลือกหมวดหมู่'**
  String get selectCategory;

  /// No description provided for @categoryLabel.
  ///
  /// In th, this message translates to:
  /// **'หมวดหมู่'**
  String get categoryLabel;

  /// No description provided for @codeSku.
  ///
  /// In th, this message translates to:
  /// **'รหัส / SKU'**
  String get codeSku;

  /// No description provided for @namesSection.
  ///
  /// In th, this message translates to:
  /// **'ชื่อเมนู'**
  String get namesSection;

  /// No description provided for @englishName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อภาษาอังกฤษ'**
  String get englishName;

  /// No description provided for @thaiName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อภาษาไทย'**
  String get thaiName;

  /// No description provided for @chineseName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อภาษาจีน'**
  String get chineseName;

  /// No description provided for @pricingDetails.
  ///
  /// In th, this message translates to:
  /// **'ราคาและรายละเอียด'**
  String get pricingDetails;

  /// No description provided for @price.
  ///
  /// In th, this message translates to:
  /// **'ราคา'**
  String get price;

  /// No description provided for @buffetIncluded.
  ///
  /// In th, this message translates to:
  /// **'รวมในบุฟเฟ่ต์'**
  String get buffetIncluded;

  /// No description provided for @priceZeroForBuffet.
  ///
  /// In th, this message translates to:
  /// **'ราคา 0 สำหรับบุฟเฟต์'**
  String get priceZeroForBuffet;

  /// No description provided for @description.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียดเพิ่มเติม'**
  String get description;

  /// No description provided for @availableActive.
  ///
  /// In th, this message translates to:
  /// **'สถานะพร้อมขาย'**
  String get availableActive;

  /// No description provided for @markAsSoldOut.
  ///
  /// In th, this message translates to:
  /// **'ปิดเพื่อแสดงว่า \"หมด\"'**
  String get markAsSoldOut;

  /// No description provided for @addImage.
  ///
  /// In th, this message translates to:
  /// **'รูปภาพ'**
  String get addImage;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเลือกหมวดหมู่'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseEnterName.
  ///
  /// In th, this message translates to:
  /// **'กรุณาระบุชื่อเมนู'**
  String get pleaseEnterName;

  /// No description provided for @newCategory.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มหมวดหมู่ใหม่'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขหมวดหมู่'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อหมวดหมู่'**
  String get categoryName;

  /// No description provided for @bluetoothPrinter.
  ///
  /// In th, this message translates to:
  /// **'เครื่องพิมพ์บลูทูธ'**
  String get bluetoothPrinter;

  /// No description provided for @scanForDevices.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาอุปกรณ์'**
  String get scanForDevices;

  /// No description provided for @connect.
  ///
  /// In th, this message translates to:
  /// **'เชื่อมต่อ'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิกการเชื่อมต่อ'**
  String get disconnect;

  /// No description provided for @testPrint.
  ///
  /// In th, this message translates to:
  /// **'ทดสอบพิมพ์'**
  String get testPrint;

  /// No description provided for @connected.
  ///
  /// In th, this message translates to:
  /// **'เชื่อมต่อแล้ว'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In th, this message translates to:
  /// **'ไม่ได้เชื่อมต่อ'**
  String get notConnected;

  /// No description provided for @scanning.
  ///
  /// In th, this message translates to:
  /// **'กำลังค้นหา...'**
  String get scanning;

  /// No description provided for @noDevicesFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบอุปกรณ์'**
  String get noDevicesFound;

  /// No description provided for @printerSettings.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่าเครื่องพิมพ์'**
  String get printerSettings;

  /// No description provided for @networkWifi.
  ///
  /// In th, this message translates to:
  /// **'เครือข่าย / WiFi'**
  String get networkWifi;

  /// No description provided for @usb.
  ///
  /// In th, this message translates to:
  /// **'USB'**
  String get usb;

  /// No description provided for @networkConfiguration.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่าเครือข่าย'**
  String get networkConfiguration;

  /// No description provided for @ipAddress.
  ///
  /// In th, this message translates to:
  /// **'IP Address'**
  String get ipAddress;

  /// No description provided for @port.
  ///
  /// In th, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @printerNetworkInfo.
  ///
  /// In th, this message translates to:
  /// **'เครื่องพิมพ์ความร้อนส่วนใหญ่ใช้ Port 9100 สำหรับระบบเครือข่าย ตรวจสอบให้แน่ใจว่าอุปกรณ์เชื่อมต่อ WiFi เดียวกัน'**
  String get printerNetworkInfo;

  /// No description provided for @usbPrintingComingSoon.
  ///
  /// In th, this message translates to:
  /// **'ระบบพิมพ์ผ่าน USB จะเปิดใช้งานเร็วๆ นี้'**
  String get usbPrintingComingSoon;

  /// No description provided for @unknownDevice.
  ///
  /// In th, this message translates to:
  /// **'อุปกรณ์ไม่ระบุชื่อ'**
  String get unknownDevice;

  /// No description provided for @noAddress.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีที่อยู่'**
  String get noAddress;

  /// No description provided for @refreshList.
  ///
  /// In th, this message translates to:
  /// **'รีเฟรชรายการ'**
  String get refreshList;

  /// No description provided for @apiSettings.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่า API'**
  String get apiSettings;

  /// No description provided for @endpointsConfig.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่า Endpoints'**
  String get endpointsConfig;

  /// No description provided for @updateMenuEndpoint.
  ///
  /// In th, this message translates to:
  /// **'Endpoint อัปเกรดเมนู'**
  String get updateMenuEndpoint;

  /// No description provided for @getOrdersEndpoint.
  ///
  /// In th, this message translates to:
  /// **'Endpoint รับออเดอร์'**
  String get getOrdersEndpoint;

  /// No description provided for @apiKeyOptional.
  ///
  /// In th, this message translates to:
  /// **'API Key (เลือกใส่)'**
  String get apiKeyOptional;

  /// No description provided for @apiSettingsSaved.
  ///
  /// In th, this message translates to:
  /// **'บันทึกตั้งค่า API แล้ว'**
  String get apiSettingsSaved;

  /// No description provided for @receiptDesigner.
  ///
  /// In th, this message translates to:
  /// **'ออกแบบใบเสร็จ'**
  String get receiptDesigner;

  /// No description provided for @setupLayout.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่าเลย์เอาท์'**
  String get setupLayout;

  /// No description provided for @customersTitle.
  ///
  /// In th, this message translates to:
  /// **'ลูกค้าสมาชิก'**
  String get customersTitle;

  /// No description provided for @addCustomer.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มลูกค้า'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขข้อมูลลูกค้า'**
  String get editCustomer;

  /// No description provided for @deleteCustomer.
  ///
  /// In th, this message translates to:
  /// **'ลบลูกค้า'**
  String get deleteCustomer;

  /// No description provided for @searchCustomerHint.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาจากชื่อหรือเบอร์โทร...'**
  String get searchCustomerHint;

  /// No description provided for @noCustomersFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบข้อมูลลูกค้า'**
  String get noCustomersFound;

  /// No description provided for @customerAdded.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มลูกค้าเรียบร้อย'**
  String get customerAdded;

  /// No description provided for @customerUpdated.
  ///
  /// In th, this message translates to:
  /// **'อัปเดตข้อมูลลูกค้าเรียบร้อย'**
  String get customerUpdated;

  /// No description provided for @customerDeleted.
  ///
  /// In th, this message translates to:
  /// **'ลบลูกค้าเรียบร้อย'**
  String get customerDeleted;

  /// No description provided for @nameRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาระบุชื่อ'**
  String get nameRequired;

  /// No description provided for @tableLayoutTitle.
  ///
  /// In th, this message translates to:
  /// **'ผังโต๊ะ'**
  String get tableLayoutTitle;

  /// No description provided for @addTable.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มโต๊ะ'**
  String get addTable;

  /// No description provided for @deleteTable.
  ///
  /// In th, this message translates to:
  /// **'ลบโต๊ะ'**
  String get deleteTable;

  /// No description provided for @tableNameLabel.
  ///
  /// In th, this message translates to:
  /// **'ชื่อโต๊ะ'**
  String get tableNameLabel;

  /// No description provided for @tableAdded.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มโต๊ะเรียบร้อย'**
  String get tableAdded;

  /// No description provided for @tableDeleted.
  ///
  /// In th, this message translates to:
  /// **'ลบโต๊ะเรียบร้อย'**
  String get tableDeleted;

  /// No description provided for @buffetTiersTitle.
  ///
  /// In th, this message translates to:
  /// **'แพ็กเกจบุฟเฟ่ต์'**
  String get buffetTiersTitle;

  /// No description provided for @addBuffetTier.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มแพ็กเกจ'**
  String get addBuffetTier;

  /// No description provided for @editBuffetTier.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขแพ็กเกจ'**
  String get editBuffetTier;

  /// No description provided for @tierAdded.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มแพ็กเกจเรียบร้อย'**
  String get tierAdded;

  /// No description provided for @tierUpdated.
  ///
  /// In th, this message translates to:
  /// **'อัปเดตแพ็กเกจเรียบร้อย'**
  String get tierUpdated;

  /// No description provided for @descriptionOptional.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียด (ไม่บังคับ)'**
  String get descriptionOptional;

  /// No description provided for @activeStatus.
  ///
  /// In th, this message translates to:
  /// **'เปิดใช้งาน'**
  String get activeStatus;

  /// No description provided for @inactiveStatus.
  ///
  /// In th, this message translates to:
  /// **'ปิดใช้งาน'**
  String get inactiveStatus;

  /// No description provided for @promotionsTitle.
  ///
  /// In th, this message translates to:
  /// **'โปรโมชั่น'**
  String get promotionsTitle;

  /// No description provided for @addPromotion.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มโปรโมชั่น'**
  String get addPromotion;

  /// No description provided for @editPromotion.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขโปรโมชั่น'**
  String get editPromotion;

  /// No description provided for @discountValue.
  ///
  /// In th, this message translates to:
  /// **'มูลค่าส่วนลด'**
  String get discountValue;

  /// No description provided for @promotionAdded.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มโปรโมชั่นเรียบร้อย'**
  String get promotionAdded;

  /// No description provided for @promotionUpdated.
  ///
  /// In th, this message translates to:
  /// **'อัปเดตโปรโมชั่นเรียบร้อย'**
  String get promotionUpdated;

  /// No description provided for @promotionDeleted.
  ///
  /// In th, this message translates to:
  /// **'ลบโปรโมชั่นเรียบร้อย'**
  String get promotionDeleted;

  /// No description provided for @visualReceiptDesignerTitle.
  ///
  /// In th, this message translates to:
  /// **'ออกแบบใบเสร็จ'**
  String get visualReceiptDesignerTitle;

  /// No description provided for @saveLayout.
  ///
  /// In th, this message translates to:
  /// **'บันทึกเลย์เอาต์'**
  String get saveLayout;

  /// No description provided for @layoutSaved.
  ///
  /// In th, this message translates to:
  /// **'บันทึกเลย์เอาต์เรียบร้อย!'**
  String get layoutSaved;

  /// No description provided for @errorSavingLayout.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาดในการบันทึก: {error}'**
  String errorSavingLayout(Object error);

  /// No description provided for @componentsTitle.
  ///
  /// In th, this message translates to:
  /// **'ส่วนประกอบ'**
  String get componentsTitle;

  /// No description provided for @propertiesTitle.
  ///
  /// In th, this message translates to:
  /// **'คุณสมบัติ'**
  String get propertiesTitle;

  /// No description provided for @selectElementToEdit.
  ///
  /// In th, this message translates to:
  /// **'เลือกรายการเพื่อแก้ไข'**
  String get selectElementToEdit;

  /// No description provided for @alignmentLabel.
  ///
  /// In th, this message translates to:
  /// **'การจัดวาง'**
  String get alignmentLabel;

  /// No description provided for @textContentLabel.
  ///
  /// In th, this message translates to:
  /// **'ข้อความ'**
  String get textContentLabel;

  /// No description provided for @fontSizeLabel.
  ///
  /// In th, this message translates to:
  /// **'ขนาดตัวอักษร'**
  String get fontSizeLabel;

  /// No description provided for @heightLabel.
  ///
  /// In th, this message translates to:
  /// **'ความสูง'**
  String get heightLabel;

  /// No description provided for @dropHere.
  ///
  /// In th, this message translates to:
  /// **'วางที่นี่'**
  String get dropHere;

  /// No description provided for @headerComponent.
  ///
  /// In th, this message translates to:
  /// **'หัวบิล'**
  String get headerComponent;

  /// No description provided for @textComponent.
  ///
  /// In th, this message translates to:
  /// **'ข้อความ'**
  String get textComponent;

  /// No description provided for @dividerComponent.
  ///
  /// In th, this message translates to:
  /// **'เส้นคั่น'**
  String get dividerComponent;

  /// No description provided for @spacerComponent.
  ///
  /// In th, this message translates to:
  /// **'ช่องว่าง'**
  String get spacerComponent;

  /// No description provided for @imageComponent.
  ///
  /// In th, this message translates to:
  /// **'รูปภาพ'**
  String get imageComponent;

  /// No description provided for @orderListComponent.
  ///
  /// In th, this message translates to:
  /// **'รายการอาหาร'**
  String get orderListComponent;

  /// No description provided for @totalsComponent.
  ///
  /// In th, this message translates to:
  /// **'ยอดรวม'**
  String get totalsComponent;

  /// No description provided for @dynamicData.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลไดนามิก'**
  String get dynamicData;

  /// No description provided for @nameLabel.
  ///
  /// In th, this message translates to:
  /// **'ชื่อ'**
  String get nameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In th, this message translates to:
  /// **'เบอร์โทร'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In th, this message translates to:
  /// **'อีเมล'**
  String get emailLabel;

  /// No description provided for @deleteTier.
  ///
  /// In th, this message translates to:
  /// **'ลบแพ็กเกจ'**
  String get deleteTier;

  /// No description provided for @tierDeleted.
  ///
  /// In th, this message translates to:
  /// **'ลบแพ็กเกจเรียบร้อย'**
  String get tierDeleted;

  /// No description provided for @noBuffetTiers.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีรายการแพ็กเกจ'**
  String get noBuffetTiers;

  /// No description provided for @deletePromotion.
  ///
  /// In th, this message translates to:
  /// **'ลบโปรโมชั่น'**
  String get deletePromotion;

  /// No description provided for @noPromotionsFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบโปรโมชั่น'**
  String get noPromotionsFound;

  /// No description provided for @selectPromotion.
  ///
  /// In th, this message translates to:
  /// **'เลือกโปรโมชั่น'**
  String get selectPromotion;

  /// No description provided for @discountLabel.
  ///
  /// In th, this message translates to:
  /// **'ส่วนลด'**
  String get discountLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In th, this message translates to:
  /// **'รวมย่อย'**
  String get subtotalLabel;

  /// No description provided for @removePromotion.
  ///
  /// In th, this message translates to:
  /// **'นำโปรโมชั่นออก'**
  String get removePromotion;

  /// No description provided for @apply.
  ///
  /// In th, this message translates to:
  /// **'ใช้'**
  String get apply;

  /// No description provided for @printReceipt.
  ///
  /// In th, this message translates to:
  /// **'พิมพ์ใบเสร็จ'**
  String get printReceipt;

  /// No description provided for @edcPayment.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินผ่าน EDC'**
  String get edcPayment;

  /// No description provided for @edcTerminal.
  ///
  /// In th, this message translates to:
  /// **'เครื่อง EDC'**
  String get edcTerminal;

  /// No description provided for @enableEdcPayment.
  ///
  /// In th, this message translates to:
  /// **'เปิดใช้งานการชำระด้วยบัตร'**
  String get enableEdcPayment;

  /// No description provided for @edcDescription.
  ///
  /// In th, this message translates to:
  /// **'รับชำระเงินผ่านเครื่องรูดบัตร EDC'**
  String get edcDescription;

  /// No description provided for @terminalType.
  ///
  /// In th, this message translates to:
  /// **'ประเภทเครื่อง'**
  String get terminalType;

  /// No description provided for @connectionType.
  ///
  /// In th, this message translates to:
  /// **'ประเภทการเชื่อมต่อ'**
  String get connectionType;

  /// No description provided for @terminalAddress.
  ///
  /// In th, this message translates to:
  /// **'ที่อยู่เครื่อง'**
  String get terminalAddress;

  /// No description provided for @addressHintSerial.
  ///
  /// In th, this message translates to:
  /// **'เช่น COM1 หรือ /dev/tty.usbserial'**
  String get addressHintSerial;

  /// No description provided for @addressHintNetwork.
  ///
  /// In th, this message translates to:
  /// **'เช่น 192.168.1.100:8000'**
  String get addressHintNetwork;

  /// No description provided for @terminalId.
  ///
  /// In th, this message translates to:
  /// **'รหัสเครื่อง (Terminal ID)'**
  String get terminalId;

  /// No description provided for @merchantId.
  ///
  /// In th, this message translates to:
  /// **'รหัสร้านค้า (Merchant ID)'**
  String get merchantId;

  /// No description provided for @testConnection.
  ///
  /// In th, this message translates to:
  /// **'ทดสอบการเชื่อมต่อ'**
  String get testConnection;

  /// No description provided for @connectionSuccess.
  ///
  /// In th, this message translates to:
  /// **'เชื่อมต่อสำเร็จ'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In th, this message translates to:
  /// **'เชื่อมต่อไม่สำเร็จ'**
  String get connectionFailed;

  /// No description provided for @waitingForCard.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเสียบหรือแตะบัตร'**
  String get waitingForCard;

  /// No description provided for @processingPayment.
  ///
  /// In th, this message translates to:
  /// **'กำลังดำเนินการชำระเงิน...'**
  String get processingPayment;

  /// No description provided for @paymentApproved.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินสำเร็จ'**
  String get paymentApproved;

  /// No description provided for @paymentDeclined.
  ///
  /// In th, this message translates to:
  /// **'บัตรถูกปฏิเสธ'**
  String get paymentDeclined;

  /// No description provided for @cardPayment.
  ///
  /// In th, this message translates to:
  /// **'บัตร (EDC)'**
  String get cardPayment;

  /// No description provided for @shiftClosedError.
  ///
  /// In th, this message translates to:
  /// **'กะปิดอยู่ กรุณาเปิดกะก่อนทำรายการ'**
  String get shiftClosedError;

  /// No description provided for @loyaltyPointsRule.
  ///
  /// In th, this message translates to:
  /// **'กติกาแต้มสะสม'**
  String get loyaltyPointsRule;

  /// No description provided for @loyaltyPointsRulePrompt.
  ///
  /// In th, this message translates to:
  /// **'ยอดใช้จ่ายกี่บาท (THB) ได้รับ 1 แต้ม?'**
  String get loyaltyPointsRulePrompt;

  /// No description provided for @bahtAmount.
  ///
  /// In th, this message translates to:
  /// **'จำนวนเงิน (บาท)'**
  String get bahtAmount;

  /// No description provided for @pointsRuleUpdated.
  ///
  /// In th, this message translates to:
  /// **'อัปเดตการตั้งค่าแต้มแล้ว'**
  String get pointsRuleUpdated;

  /// No description provided for @selectCustomer.
  ///
  /// In th, this message translates to:
  /// **'เลือกลูกค้า'**
  String get selectCustomer;

  /// No description provided for @layoutDesigner.
  ///
  /// In th, this message translates to:
  /// **'ออกแบบแปลนร้าน'**
  String get layoutDesigner;

  /// No description provided for @tools.
  ///
  /// In th, this message translates to:
  /// **'เครื่องมือ'**
  String get tools;

  /// No description provided for @properties.
  ///
  /// In th, this message translates to:
  /// **'คุณสมบัติ'**
  String get properties;

  /// No description provided for @width.
  ///
  /// In th, this message translates to:
  /// **'ความกว้าง'**
  String get width;

  /// No description provided for @height.
  ///
  /// In th, this message translates to:
  /// **'ความสูง'**
  String get height;

  /// No description provided for @rotation.
  ///
  /// In th, this message translates to:
  /// **'การหมุน'**
  String get rotation;

  /// No description provided for @duplicate.
  ///
  /// In th, this message translates to:
  /// **'ทำซ้ำ'**
  String get duplicate;

  /// No description provided for @toFront.
  ///
  /// In th, this message translates to:
  /// **'ย้ายไปข้างหน้า'**
  String get toFront;

  /// No description provided for @toBack.
  ///
  /// In th, this message translates to:
  /// **'ย้ายไปข้างหลัง'**
  String get toBack;

  /// No description provided for @icon.
  ///
  /// In th, this message translates to:
  /// **'ไอคอน'**
  String get icon;

  /// No description provided for @fillColor.
  ///
  /// In th, this message translates to:
  /// **'สีพื้นหลัง'**
  String get fillColor;

  /// No description provided for @wall.
  ///
  /// In th, this message translates to:
  /// **'กำแพง'**
  String get wall;

  /// No description provided for @plant.
  ///
  /// In th, this message translates to:
  /// **'ต้นไม้'**
  String get plant;

  /// No description provided for @door.
  ///
  /// In th, this message translates to:
  /// **'ประตู'**
  String get door;

  /// No description provided for @chair.
  ///
  /// In th, this message translates to:
  /// **'เก้าอี้'**
  String get chair;

  /// No description provided for @couch.
  ///
  /// In th, this message translates to:
  /// **'โซฟา'**
  String get couch;

  /// No description provided for @tv.
  ///
  /// In th, this message translates to:
  /// **'ทีวี'**
  String get tv;

  /// No description provided for @music.
  ///
  /// In th, this message translates to:
  /// **'เครื่องเสียง'**
  String get music;

  /// No description provided for @wifi.
  ///
  /// In th, this message translates to:
  /// **'ไวไฟ'**
  String get wifi;

  /// No description provided for @fan.
  ///
  /// In th, this message translates to:
  /// **'พัดลม'**
  String get fan;

  /// No description provided for @fire.
  ///
  /// In th, this message translates to:
  /// **'ถังดับเพลิง'**
  String get fire;

  /// No description provided for @restroom.
  ///
  /// In th, this message translates to:
  /// **'ห้องน้ำ'**
  String get restroom;

  /// No description provided for @kitchen.
  ///
  /// In th, this message translates to:
  /// **'ครัว'**
  String get kitchen;

  /// No description provided for @bar.
  ///
  /// In th, this message translates to:
  /// **'บาร์'**
  String get bar;

  /// No description provided for @cashier.
  ///
  /// In th, this message translates to:
  /// **'แคชเชียร์'**
  String get cashier;

  /// No description provided for @none.
  ///
  /// In th, this message translates to:
  /// **'ไม่มี'**
  String get none;

  /// No description provided for @object.
  ///
  /// In th, this message translates to:
  /// **'วัตถุ'**
  String get object;

  /// No description provided for @selectItem.
  ///
  /// In th, this message translates to:
  /// **'เลือกรายการ'**
  String get selectItem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
