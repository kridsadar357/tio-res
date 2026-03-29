import '../services/database_helper.dart';

/// Translation mapping for common Thai buffet/shabu items
/// Thai name -> {en: English, cn: Chinese}
const Map<String, Map<String, String>> translations = {
  // Vegetables
  'กะหล่ำ': {'en': 'Cabbage', 'cn': '卷心菜'},
  'กะหล่ำปลี': {'en': 'Cabbage', 'cn': '卷心菜'},
  'ผักกาด': {'en': 'Lettuce', 'cn': '生菜'},
  'ผักบุ้ง': {'en': 'Morning Glory', 'cn': '空心菜'},
  'ผักกวางตุ้ง': {'en': 'Chinese Cabbage', 'cn': '青菜'},
  'ข้าวโพด': {'en': 'Corn', 'cn': '玉米'},
  'ข้าวโพดอ่อน': {'en': 'Baby Corn', 'cn': '玉米笋'},
  'ขึ้นฉ่าย': {'en': 'Celery', 'cn': '芹菜'},
  'ค่าบุฟเฟ่ต์': {'en': 'Buffet Fee', 'cn': '自助餐费'},
  'เห็ดหอม': {'en': 'Shiitake Mushroom', 'cn': '香菇'},
  'เห็ดเข็มทอง': {'en': 'Enoki Mushroom', 'cn': '金针菇'},
  'เห็ดนางฟ้า': {'en': 'Oyster Mushroom', 'cn': '平菇'},
  'เห็ดหูหนู': {'en': 'Wood Ear Mushroom', 'cn': '木耳'},
  'ฟักทอง': {'en': 'Pumpkin', 'cn': '南瓜'},
  'แครอท': {'en': 'Carrot', 'cn': '胡萝卜'},
  'มันฝรั่ง': {'en': 'Potato', 'cn': '土豆'},
  'มันเทศ': {'en': 'Sweet Potato', 'cn': '红薯'},
  'เต้าหู้': {'en': 'Tofu', 'cn': '豆腐'},
  'เต้าหู้ไข่': {'en': 'Egg Tofu', 'cn': '鸡蛋豆腐'},
  'วุ้นเส้น': {'en': 'Glass Noodles', 'cn': '粉丝'},
  'บะหมี่': {'en': 'Egg Noodles', 'cn': '鸡蛋面'},
  'มาม่า': {'en': 'Instant Noodles', 'cn': '方便面'},
  
  // Seafood
  'กุ้ง': {'en': 'Shrimp', 'cn': '虾'},
  'กุ้งสด': {'en': 'Fresh Shrimp', 'cn': '鲜虾'},
  'กุ้งแม่น้ำ': {'en': 'River Prawn', 'cn': '河虾'},
  'ปลาหมึก': {'en': 'Squid', 'cn': '鱿鱼'},
  'หอยแมลงภู่': {'en': 'Mussels', 'cn': '青口'},
  'หอยนางรม': {'en': 'Oyster', 'cn': '牡蛎'},
  'หอยแครง': {'en': 'Cockle', 'cn': '血蚶'},
  'ปู': {'en': 'Crab', 'cn': '螃蟹'},
  'ปลา': {'en': 'Fish', 'cn': '鱼'},
  'ปลาแซลม่อน': {'en': 'Salmon', 'cn': '三文鱼'},
  'ลูกชิ้นปลา': {'en': 'Fish Ball', 'cn': '鱼丸'},
  
  // Meat
  'เนื้อหมู': {'en': 'Pork', 'cn': '猪肉'},
  'หมูสไลด์': {'en': 'Sliced Pork', 'cn': '猪肉片'},
  'หมูสามชั้น': {'en': 'Pork Belly', 'cn': '五花肉'},
  'หมูกรอบ': {'en': 'Crispy Pork', 'cn': '脆皮猪肉'},
  'เนื้อวัว': {'en': 'Beef', 'cn': '牛肉'},
  'เนื้อสไลด์': {'en': 'Sliced Beef', 'cn': '牛肉片'},
  'เนื้อติดมัน': {'en': 'Marbled Beef', 'cn': '雪花牛肉'},
  'เนื้อไก่': {'en': 'Chicken', 'cn': '鸡肉'},
  'ปีกไก่': {'en': 'Chicken Wings', 'cn': '鸡翅'},
  'น่องไก่': {'en': 'Chicken Drumstick', 'cn': '鸡腿'},
  'ไส้กรอก': {'en': 'Sausage', 'cn': '香肠'},
  'เบคอน': {'en': 'Bacon', 'cn': '培根'},
  'ลูกชิ้นหมู': {'en': 'Pork Ball', 'cn': '猪肉丸'},
  'ลูกชิ้นเนื้อ': {'en': 'Beef Ball', 'cn': '牛肉丸'},
  
  // Processed/Others
  'ไข่ไก่': {'en': 'Chicken Egg', 'cn': '鸡蛋'},
  'ไข่': {'en': 'Egg', 'cn': '蛋'},
  'ไข่นกกระทา': {'en': 'Quail Egg', 'cn': '鹌鹑蛋'},
  'ปอเปี๊ยะทอด': {'en': 'Spring Rolls', 'cn': '春卷'},
  'เกี๊ยวซ่า': {'en': 'Gyoza', 'cn': '饺子'},
  'สลัดผัก': {'en': 'Vegetable Salad', 'cn': '蔬菜沙拉'},
  
  // Desserts & Drinks
  'ไอศกรีม': {'en': 'Ice Cream', 'cn': '冰淇淋'},
  'เค้ก': {'en': 'Cake', 'cn': '蛋糕'},
  'ผลไม้': {'en': 'Fruit', 'cn': '水果'},
  'น้ำเปล่า': {'en': 'Water', 'cn': '水'},
  'น้ำอัดลม': {'en': 'Soft Drink', 'cn': '汽水'},
  'ชาเย็น': {'en': 'Thai Iced Tea', 'cn': '泰式冰茶'},
  'กาแฟเย็น': {'en': 'Iced Coffee', 'cn': '冰咖啡'},
  'เบียร์ช้าง': {'en': 'Chang Beer', 'cn': '大象啤酒'},
  'เบียร์สิงห์': {'en': 'Singha Beer', 'cn': '胜狮啤酒'},
  'เหล้าไวน์': {'en': 'Wine', 'cn': '红酒'},
  
  // Soups/Sauces
  'ต้มยำ': {'en': 'Tom Yum', 'cn': '冬阴功'},
  'น้ำซุปใส': {'en': 'Clear Soup', 'cn': '清汤'},
  'น้ำจิ้ม': {'en': 'Dipping Sauce', 'cn': '蘸酱'},
  
  // Rice
  'ข้าวสวย': {'en': 'Steamed Rice', 'cn': '白米饭'},
  'ข้าวเหนียว': {'en': 'Sticky Rice', 'cn': '糯米饭'},
  'ข้าวผัด': {'en': 'Fried Rice', 'cn': '炒饭'},
  'ข้าวเหนียวมะม่วง': {'en': 'Mango Sticky Rice', 'cn': '芒果糯米饭'},
  
  // Categories
  'บุฟเฟ่ต์': {'en': 'Buffet', 'cn': '自助餐'},
  'ทั่วไป': {'en': 'General', 'cn': '一般'},
  'เนื้อวัว 🥩': {'en': 'Beef 🥩', 'cn': '牛肉 🥩'},
  'เนื้อ': {'en': 'Meat', 'cn': '肉类'},
  'อาหารทะเล': {'en': 'Seafood', 'cn': '海鲜'},
  'ผัก': {'en': 'Vegetables', 'cn': '蔬菜'},
  'เครื่องดื่ม': {'en': 'Drinks', 'cn': '饮料'},
  'ของหวาน': {'en': 'Dessert', 'cn': '甜点'},
};

/// Apply translations to menu items in the database
/// This will:
/// 1. Clear any wrong name_en values that contain Thai text
/// 2. Add proper English translations
/// 3. Add Chinese translations
Future<int> applyMenuTranslations() async {
  final db = await DatabaseHelper().database;
  
  int updatedCount = 0;
  
  // Get all menu items
  final items = await db.query('menu_items');
  
  for (final item in items) {
    final thaiName = item['name'] as String?;
    if (thaiName == null) continue;
    
    // Find translation
    final trans = translations[thaiName.trim()];
    if (trans != null) {
      await db.update(
        'menu_items',
        {
          'name_en': trans['en'],
          'name_cn': trans['cn'],
        },
        where: 'id = ?',
        whereArgs: [item['id']],
      );
      updatedCount++;
    }
  }
  
  // Also update categories
  final categories = await db.query('menu_categories');
  for (final cat in categories) {
    final thaiName = cat['name'] as String?;
    if (thaiName == null) continue;
    
    final trans = translations[thaiName.trim()];
    if (trans != null) {
      await db.update(
        'menu_categories',
        {
          'name_en': trans['en'],
          'name_cn': trans['cn'],
        },
        where: 'id = ?',
        whereArgs: [cat['id']],
      );
      updatedCount++;
    }
  }
  
  return updatedCount;
}
