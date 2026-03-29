import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';
import '../models/table_model.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/transaction.dart';
import '../models/layout_object_model.dart';

/// DatabaseHelper: Singleton class managing SQLite database operations
/// Handles all CRUD operations for the Buffet Restaurant POS system
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static sqflite.Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Use constants from AppConstants
  static const String _databaseName = AppConstants.databaseName;
  static const int _databaseVersion = AppConstants.databaseVersion;

  /// Initialize database connection
  Future<sqflite.Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Create database with all tables
  Future<sqflite.Database> _initDB() async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await sqflite.openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables on database creation
  Future<void> _onCreate(sqflite.Database db, int version) async {
    // Create tables table with all V8 columns
    await db.execute('''
      CREATE TABLE ${AppConstants.tablesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT ${AppConstants.tableAvailable},
        current_order_id INTEGER,
        x REAL DEFAULT 0,
        y REAL DEFAULT 0,
        width REAL DEFAULT 80,
        height REAL DEFAULT 80,
        rotation REAL DEFAULT 0,
        shape TEXT DEFAULT "rectangle",
        color INTEGER DEFAULT 0xFF4CAF50
      )
    ''');

    // Menu Categories table
    await db.execute('''
      CREATE TABLE ${AppConstants.menuCategoriesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_en TEXT,
        name_cn TEXT,
        icon_path TEXT
      )
    ''');

    // Menu Items table
    await db.execute('''
      CREATE TABLE ${AppConstants.menuItemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_en TEXT,
        name_th TEXT,
        name_cn TEXT,
        category_id INTEGER NOT NULL,
        price REAL NOT NULL DEFAULT 0.0,
        image_path TEXT,
        is_buffet_included INTEGER NOT NULL DEFAULT 1,
        description TEXT,
        sku TEXT,
        status INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Orders table (with all V10 columns including customer_id and points_earned)
    await db.execute('''
      CREATE TABLE ${AppConstants.ordersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_id INTEGER,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        adult_headcount INTEGER NOT NULL DEFAULT 0,
        child_headcount INTEGER NOT NULL DEFAULT 0,
        buffet_tier_price REAL NOT NULL DEFAULT 0.0,
        total_amount REAL NOT NULL DEFAULT 0.0,
        payment_method TEXT,
        amount_received REAL,
        status TEXT NOT NULL DEFAULT '${AppConstants.orderOpen}',
        promotion_id INTEGER,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        customer_id INTEGER,
        points_earned INTEGER DEFAULT 0,
        FOREIGN KEY (table_id) REFERENCES ${AppConstants.tablesTable}(id) ON DELETE CASCADE
      )
    ''');

    // Order Items table (items ordered to a table)
    await db.execute('''
      CREATE TABLE ${AppConstants.orderItemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        menu_item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        price_at_moment REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (order_id) REFERENCES ${AppConstants.ordersTable}(id) ON DELETE CASCADE,
        FOREIGN KEY (menu_item_id) REFERENCES ${AppConstants.menuItemsTable}(id)
      )
    ''');

    // Transactions table (separate from orders for payment history)
    await db.execute('''
      CREATE TABLE ${AppConstants.transactionsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        amount_received REAL,
        change_amount REAL,
        transaction_time INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES ${AppConstants.ordersTable}(id)
      )
    ''');

    // Shifts table
    await db.execute('''
      CREATE TABLE ${AppConstants.shiftsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        starting_cash REAL NOT NULL,
        expected_cash REAL,
        actual_cash REAL,
        status TEXT NOT NULL DEFAULT '${AppConstants.shiftOpen}'
      )
    ''');

    // Buffet Tiers table
    await db.execute('''
      CREATE TABLE ${AppConstants.buffetTiersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        excluded_category_ids TEXT
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE ${AppConstants.customersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        points INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Promotions table
    await db.execute('''
      CREATE TABLE ${AppConstants.promotionsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        discount_type TEXT NOT NULL,
        discount_value REAL NOT NULL,
        start_date INTEGER,
        end_date INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Layout Objects table (Missing in V1)
    await db.execute('''
      CREATE TABLE ${AppConstants.layoutObjectsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        rotation REAL DEFAULT 0,
        color INTEGER,
        label TEXT,
        z_index INTEGER DEFAULT 0,
        icon_point INTEGER
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_table_status ON ${AppConstants.tablesTable}(status)');
    await db.execute(
        'CREATE INDEX idx_menu_category ON ${AppConstants.menuItemsTable}(category_id)');
    await db.execute('CREATE INDEX idx_order_table ON ${AppConstants.ordersTable}(table_id)');
    await db.execute('CREATE INDEX idx_order_status ON ${AppConstants.ordersTable}(status)');
    await db.execute(
        'CREATE INDEX idx_orderitem_order ON ${AppConstants.orderItemsTable}(order_id)');

    // Insert default data
    await _insertDefaultData(db);
  }

  /// Handle database upgrades
  /// Handle database upgrades
  Future<void> _onUpgrade(
      sqflite.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // V1 -> V2: Add multi-language, sku, description, status to menu_items
      await db.execute('ALTER TABLE ${AppConstants.menuItemsTable} ADD COLUMN name_th TEXT');
      await db.execute('ALTER TABLE ${AppConstants.menuItemsTable} ADD COLUMN name_cn TEXT');
      await db
          .execute('ALTER TABLE ${AppConstants.menuItemsTable} ADD COLUMN description TEXT');
      await db.execute('ALTER TABLE ${AppConstants.menuItemsTable} ADD COLUMN sku TEXT');
      await db.execute(
          'ALTER TABLE ${AppConstants.menuItemsTable} ADD COLUMN status INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 3) {
      // V2 -> V3: Add shifts table
      await db.execute('''
        CREATE TABLE ${AppConstants.shiftsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          starting_cash REAL NOT NULL,
          expected_cash REAL,
          actual_cash REAL,
          status TEXT NOT NULL DEFAULT '${AppConstants.shiftOpen}'
        )
      ''');
    }
    if (oldVersion < 4) {
      // V3 -> V4: Add buffet_tiers, customers, promotions tables
      await db.execute('''
        CREATE TABLE ${AppConstants.buffetTiersTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          description TEXT,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE ${AppConstants.customersTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          points INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE ${AppConstants.promotionsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          discount_type TEXT NOT NULL,
          discount_value REAL NOT NULL,
          start_date INTEGER,
          end_date INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
      // Insert default buffet tiers
      await db.insert(AppConstants.buffetTiersTable,
          {'name': 'Standard', 'price': 25.0, 'is_active': 1});
      await db.insert(
          AppConstants.buffetTiersTable, {'name': 'Premium', 'price': 35.0, 'is_active': 1});
      await db.insert(
          AppConstants.buffetTiersTable, {'name': 'VIP', 'price': 50.0, 'is_active': 1});
    }
    if (oldVersion < 5) {
      // V4 -> V5: Add promotion_id and discount_amount to orders
      await db
          .execute('ALTER TABLE ${AppConstants.ordersTable} ADD COLUMN promotion_id INTEGER');
      await db.execute(
          'ALTER TABLE ${AppConstants.ordersTable} ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0.0');
    }
    if (oldVersion < 6) {
      // V5 -> V6: Add layout fields to tables and create layout_objects table
      // Add layout fields to tables table
      await db.execute('ALTER TABLE ${AppConstants.tablesTable} ADD COLUMN x REAL DEFAULT 0');
      await db.execute('ALTER TABLE ${AppConstants.tablesTable} ADD COLUMN y REAL DEFAULT 0');
      await db
          .execute('ALTER TABLE ${AppConstants.tablesTable} ADD COLUMN width REAL DEFAULT 80');
      await db.execute(
          'ALTER TABLE ${AppConstants.tablesTable} ADD COLUMN height REAL DEFAULT 80');
      await db.execute(
          'ALTER TABLE ${AppConstants.tablesTable} ADD COLUMN rotation REAL DEFAULT 0');
      await db.execute(
          'ALTER TABLE ${AppConstants.tablesTable} ADD COLUMN shape TEXT DEFAULT "rectangle"');
      await db.execute(
          'ALTER TABLE ${AppConstants.tablesTable} ADD COLUMN color INTEGER DEFAULT 0xFF4CAF50'); // Default Green

      // Create layout_objects table
      await db.execute('''
        CREATE TABLE ${AppConstants.layoutObjectsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          x REAL NOT NULL,
          y REAL NOT NULL,
          width REAL NOT NULL,
          height REAL NOT NULL,
          rotation REAL DEFAULT 0,
          color INTEGER,
          label TEXT,
          z_index INTEGER DEFAULT 0,
          icon_point INTEGER
        )
      ''');
    }
    if (oldVersion < 7) {
      // V6 -> V7: Add icon_point to layout_objects
      await db.execute(
          'ALTER TABLE ${AppConstants.layoutObjectsTable} ADD COLUMN icon_point INTEGER');
    }
    if (oldVersion < 8) {
      // V7 -> V8: Allow NULL table_id for takeaway orders
      // SQLite doesn't support ALTER COLUMN, so we need to recreate the table
      await db.execute('ALTER TABLE ${AppConstants.ordersTable} RENAME TO orders_old');
      await db.execute('''
        CREATE TABLE ${AppConstants.ordersTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_id INTEGER,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          adult_headcount INTEGER NOT NULL DEFAULT 0,
          child_headcount INTEGER NOT NULL DEFAULT 0,
          buffet_tier_price REAL NOT NULL DEFAULT 0.0,
          total_amount REAL NOT NULL DEFAULT 0.0,
          payment_method TEXT,
          amount_received REAL,
          status TEXT NOT NULL DEFAULT '${AppConstants.orderOpen}',
          promotion_id INTEGER,
          discount_amount REAL NOT NULL DEFAULT 0.0
        )
      ''');
      // Copy only common columns from old table
      await db.execute('''
        INSERT INTO ${AppConstants.ordersTable} (id, table_id, start_time, end_time, adult_headcount, 
                                   child_headcount, buffet_tier_price, total_amount, 
                                   payment_method, status)
        SELECT id, table_id, start_time, end_time, adult_headcount, 
               child_headcount, buffet_tier_price, total_amount, 
               payment_method, status
        FROM orders_old
      ''');
      await db.execute('DROP TABLE orders_old');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.layoutObjectsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          x REAL NOT NULL,
          y REAL NOT NULL,
          width REAL NOT NULL,
          height REAL NOT NULL,
          rotation REAL DEFAULT 0,
          color INTEGER,
          label TEXT,
          z_index INTEGER DEFAULT 0,
          icon_point INTEGER
        )
      ''');

      final columns = [
        'x REAL DEFAULT 0',
        'y REAL DEFAULT 0',
        'width REAL DEFAULT 80',
        'height REAL DEFAULT 80',
        'rotation REAL DEFAULT 0',
        'shape TEXT DEFAULT "rectangle"',
        'color INTEGER DEFAULT 0xFF4CAF50'
      ];

      for (final col in columns) {
        try {
          await db.execute('ALTER TABLE ${AppConstants.tablesTable} ADD COLUMN $col');
        } catch (e) {
          // Ignore error
        }
      }
    }
    if (oldVersion < 10) {
      // V9 -> V10: Add customer_id and points_earned to orders
      await db
          .execute('ALTER TABLE ${AppConstants.ordersTable} ADD COLUMN customer_id INTEGER');
      await db.execute(
          'ALTER TABLE ${AppConstants.ordersTable} ADD COLUMN points_earned INTEGER DEFAULT 0');
    }
    if (oldVersion < 11) {
      // V10 -> V11: Add multi-language columns to categories
      await db.execute(
          'ALTER TABLE ${AppConstants.menuCategoriesTable} ADD COLUMN name_en TEXT');
      await db.execute(
          'ALTER TABLE ${AppConstants.menuCategoriesTable} ADD COLUMN name_cn TEXT');
    }
    if (oldVersion < 12) {
      // V11 -> V12: Add excluded_category_ids to buffet_tiers
      await db.execute(
          'ALTER TABLE ${AppConstants.buffetTiersTable} ADD COLUMN excluded_category_ids TEXT');
    }
    if (oldVersion < 13) {
      // V12 -> V13: Add name_en to menu_items (missed in V2)
      await db.execute(
          'ALTER TABLE ${AppConstants.menuItemsTable} ADD COLUMN name_en TEXT');
    }
  }

  /// Insert default categories and menu items
  Future<void> _insertDefaultData(sqflite.Database db) async {
    // Default menu categories
    final defaultCategories = [
      {'name': 'Buffet Main', 'icon_path': 'assets/icons/buffet.png'},
      {'name': 'Appetizers', 'icon_path': 'assets/icons/appetizers.png'},
      {'name': 'Main Course', 'icon_path': 'assets/icons/main.png'},
      {'name': 'Desserts', 'icon_path': 'assets/icons/desserts.png'},
      {'name': 'Drinks', 'icon_path': 'assets/icons/drinks.png'},
      {'name': 'Alcohol', 'icon_path': 'assets/icons/alcohol.png'},
    ];

    for (final category in defaultCategories) {
      await db.insert(AppConstants.menuCategoriesTable, category);
    }

    // Default tables (create 12 tables)
    for (int i = 1; i <= 12; i++) {
      await db.insert(AppConstants.tablesTable, {
        'table_name': 'T$i',
        'status': AppConstants.tableAvailable,
        'current_order_id': null,
      });
    }

    // Default buffet tiers
    await db.insert(
        AppConstants.buffetTiersTable, {'name': 'Standard', 'price': 299.0, 'is_active': 1});
    await db.insert(
        AppConstants.buffetTiersTable, {'name': 'Premium', 'price': 399.0, 'is_active': 1});
    await db.insert(
        AppConstants.buffetTiersTable, {'name': 'VIP', 'price': 599.0, 'is_active': 1});

    // Default menu items (Thai restaurant style)
    final defaultItems = [
      // Buffet Main (category_id: 1)
      {
        'name': 'ค่าบุฟเฟ่ต์',
        'category_id': 1,
        'price': 299.0,
        'is_buffet_included': 1
      },
      // Appetizers (category_id: 2)
      {
        'name': 'ปอเปี๊ยะทอด',
        'category_id': 2,
        'price': 0.0,
        'is_buffet_included': 1
      },
      {
        'name': 'เกี๊ยวซ่า',
        'category_id': 2,
        'price': 0.0,
        'is_buffet_included': 1
      },
      {
        'name': 'สลัดผัก',
        'category_id': 2,
        'price': 0.0,
        'is_buffet_included': 1
      },
      // Main Course (category_id: 3)
      {
        'name': 'เนื้อหมู',
        'category_id': 3,
        'price': 0.0,
        'is_buffet_included': 1
      },
      {
        'name': 'เนื้อวัว',
        'category_id': 3,
        'price': 0.0,
        'is_buffet_included': 1
      },
      {
        'name': 'เนื้อไก่',
        'category_id': 3,
        'price': 0.0,
        'is_buffet_included': 1
      },
      {'name': 'กุ้ง', 'category_id': 3, 'price': 0.0, 'is_buffet_included': 1},
      {
        'name': 'ปลาหมึก',
        'category_id': 3,
        'price': 0.0,
        'is_buffet_included': 1
      },
      {
        'name': 'หอยแมลงภู่',
        'category_id': 3,
        'price': 0.0,
        'is_buffet_included': 1
      },
      // Desserts (category_id: 4)
      {
        'name': 'ไอศกรีม',
        'category_id': 4,
        'price': 0.0,
        'is_buffet_included': 1
      },
      {'name': 'เค้ก', 'category_id': 4, 'price': 0.0, 'is_buffet_included': 1},
      {
        'name': 'ผลไม้',
        'category_id': 4,
        'price': 0.0,
        'is_buffet_included': 1
      },
      // Drinks (category_id: 5)
      {
        'name': 'น้ำเปล่า',
        'category_id': 5,
        'price': 0.0,
        'is_buffet_included': 1
      },
      {
        'name': 'น้ำอัดลม',
        'category_id': 5,
        'price': 35.0,
        'is_buffet_included': 0
      },
      {
        'name': 'ชาเย็น',
        'category_id': 5,
        'price': 45.0,
        'is_buffet_included': 0
      },
      {
        'name': 'กาแฟเย็น',
        'category_id': 5,
        'price': 55.0,
        'is_buffet_included': 0
      },
      // Alcohol (category_id: 6)
      {
        'name': 'เบียร์ช้าง',
        'category_id': 6,
        'price': 80.0,
        'is_buffet_included': 0
      },
      {
        'name': 'เบียร์สิงห์',
        'category_id': 6,
        'price': 85.0,
        'is_buffet_included': 0
      },
      {
        'name': 'เหล้าไวน์',
        'category_id': 6,
        'price': 150.0,
        'is_buffet_included': 0
      },
    ];

    for (final item in defaultItems) {
      await db.insert(AppConstants.menuItemsTable, {
        ...item,
        'status': 1, // Available
      });
    }
  }

  // ==================== TABLE MANAGEMENT ====================

  /// Get all tables with their current status and calculated totals
  Future<List<TableModel>> getAllTables() async {
    final db = await database;

    // We need to fetch tables and, if occupied, the current total amount.
    // The total amount is: (adults + children) * tier_price + sum(order_items.price * quantity)
    // We can do this with a subquery or by fetching and calculating in Dart.
    // For performance and cleaner model mapping, a raw query is best.

    const sql = '''
      SELECT 
        t.*,
        CASE 
          WHEN t.status = 1 AND t.current_order_id IS NOT NULL THEN (
             -- Calculate Buffet Cost
             (SELECT (o.adult_headcount + o.child_headcount) * o.buffet_tier_price 
              FROM ${AppConstants.ordersTable} o 
              WHERE o.id = t.current_order_id)
             +
             -- Calculate Extra Items Cost
             COALESCE(
               (SELECT SUM(oi.price_at_moment * oi.quantity) 
                FROM ${AppConstants.orderItemsTable} oi 
                WHERE oi.order_id = t.current_order_id), 
             0.0)
          )
          ELSE NULL 
        END as current_total_amount
      FROM ${AppConstants.tablesTable} t
      ORDER BY t.id ASC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql);
    return List.generate(maps.length, (i) => TableModel.fromMap(maps[i]));
  }

  /// Get a specific table by ID
  Future<TableModel?> getTable(int tableId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tablesTable,
      where: 'id = ?',
      whereArgs: [tableId],
    );
    if (maps.isEmpty) return null;
    return TableModel.fromMap(maps.first);
  }

  /// Update table status
  Future<int> updateTableStatus(int tableId, int status,
      {int? currentOrderId}) async {
    final db = await database;
    return await db.update(
      AppConstants.tablesTable,
      {
        'status': status,
        if (currentOrderId != null) 'current_order_id': currentOrderId,
      },
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }

  /// Add a new table
  Future<int> addTable(String tableName) async {
    final db = await database;
    return await db.insert(AppConstants.tablesTable, {
      'table_name': tableName,
      'status': AppConstants.tableAvailable,
      'current_order_id': null,
    });
  }

  /// Delete a table (only if not occupied)
  Future<int> deleteTable(int tableId) async {
    final db = await database;
    return await db.delete(
      AppConstants.tablesTable,
      where: 'id = ? AND status = ?',
      whereArgs: [tableId, AppConstants.tableAvailable],
    );
  }

  /// Update table layout (x, y, width, height, etc)
  Future<int> updateTableLayout(TableModel table) async {
    final db = await database;
    return await db.update(
      AppConstants.tablesTable,
      table.toMap(),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  // ==================== LAYOUT OBJECTS MANAGEMENT ====================

  /// Get all layout objects (walls, furniture, etc)
  Future<List<LayoutObjectModel>> getAllLayoutObjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.layoutObjectsTable);
    return List.generate(
        maps.length, (i) => LayoutObjectModel.fromMap(maps[i]));
  }

  /// Add new layout object
  Future<int> addLayoutObject(LayoutObjectModel object) async {
    final db = await database;
    return await db.insert(AppConstants.layoutObjectsTable, object.toMap());
  }

  /// Update layout object
  Future<int> updateLayoutObject(LayoutObjectModel object) async {
    final db = await database;
    return await db.update(
      AppConstants.layoutObjectsTable,
      object.toMap(),
      where: 'id = ?',
      whereArgs: [object.id],
    );
  }

  /// Delete layout object
  Future<int> deleteLayoutObject(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.layoutObjectsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Open a table (create new order session)
  /// This is the core buffet logic: capturing headcount and tier price
  Future<int> openTable({
    required int tableId,
    required int adults,
    required int children,
    required double buffetTierPrice,
  }) async {
    final db = await database;

    // Start transaction
    return await db.transaction((txn) async {
      // Create new order
      final orderId = await txn.insert(
        AppConstants.ordersTable,
        {
          'table_id': tableId,
          'start_time': DateTime.now().millisecondsSinceEpoch,
          'adult_headcount': adults,
          'child_headcount': children,
          'buffet_tier_price': buffetTierPrice,
          'total_amount': 0.0, // Will be calculated at checkout
          'status': AppConstants.orderOpen,
        },
      );

      // Update table status to occupied
      await txn.update(
        AppConstants.tablesTable,
        {
          'status': AppConstants.tableOccupied,
          'current_order_id': orderId,
        },
        where: 'id = ?',
        whereArgs: [tableId],
      );

      return orderId;
    });
  }

  /// Create a takeaway order (no table assignment)
  /// This creates an order that can be checked out immediately
  Future<int> createTakeawayOrder() async {
    final db = await database;

    final orderId = await db.insert(
      AppConstants.ordersTable,
      {
        'table_id': null, // No table for takeaway
        'start_time': DateTime.now().millisecondsSinceEpoch,
        'adult_headcount': 0,
        'child_headcount': 0,
        'buffet_tier_price': 0.0,
        'total_amount': 0.0,
          'status': AppConstants.orderOpen,
      },
    );

    return orderId;
  }

  /// Close a table (move to cleaning status)
  Future<int> closeTable(int tableId) async {
    return await updateTableStatus(tableId, AppConstants.tableCleaning,
        currentOrderId: null);
  }

  /// Make table available again
  Future<int> markTableAvailable(int tableId) async {
    return await updateTableStatus(tableId, AppConstants.tableAvailable);
  }

  /// Cancel an OPEN table (Undo Open)
  /// This voids the current order and frees the table
  Future<void> cancelTableOrder(int tableId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Get the current order ID
      final List<Map<String, dynamic>> result = await txn.query(
        AppConstants.tablesTable,
        columns: ['current_order_id'],
        where: 'id = ?',
        whereArgs: [tableId],
      );

      if (result.isEmpty || result.first['current_order_id'] == null) {
        return; // Nothing to cancel
      }

      final int orderId = result.first['current_order_id'];

      // 2. Update Order status to Cancelled (-1)
      await txn.update(
        AppConstants.ordersTable,
        {'status': AppConstants.orderCancelled, 'end_time': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [orderId],
      );

      // 3. Set Table status back to Available (0)
      await txn.update(
        AppConstants.tablesTable,
        {'status': AppConstants.tableAvailable, 'current_order_id': null},
        where: 'id = ?',
        whereArgs: [tableId],
      );
    });
  }

  /// Move an Order from one table to another
  /// Requires 'toTable' to be available
  Future<void> moveTable(int fromTableId, int toTableId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Get current order from Origin Table
      final List<Map<String, dynamic>> fromTableResult = await txn.query(
        AppConstants.tablesTable,
        columns: ['current_order_id'],
        where: 'id = ?',
        whereArgs: [fromTableId],
      );

      if (fromTableResult.isEmpty || fromTableResult.first['current_order_id'] == null) {
        throw Exception('Source table has no active order');
      }

      final int orderId = fromTableResult.first['current_order_id'];

      // 2. Check if Destination Table is available
      final List<Map<String, dynamic>> toTableResult = await txn.query(
        AppConstants.tablesTable,
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [toTableId],
      );

      if (toTableResult.isEmpty) throw Exception('Destination table not found');
      if (toTableResult.first['status'] != AppConstants.tableAvailable) {
        throw Exception('Destination table is not available');
      }

      // 3. Update Order record with new table_id
      await txn.update(
        AppConstants.ordersTable,
        {'table_id': toTableId},
        where: 'id = ?',
        whereArgs: [orderId],
      );

      // 4. Update Destination Table (Occupied, set order ID)
      await txn.update(
        AppConstants.tablesTable,
        {'status': AppConstants.tableOccupied, 'current_order_id': orderId},
        where: 'id = ?',
        whereArgs: [toTableId],
      );

      // 5. Update Source Table (Available, clear order ID)
      await txn.update(
        AppConstants.tablesTable,
        {'status': AppConstants.tableAvailable, 'current_order_id': null},
        where: 'id = ?',
        whereArgs: [fromTableId],
      );
    });
  }

  // ==================== MENU MANAGEMENT ====================

  /// Get all menu categories
  Future<List<MenuCategory>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.menuCategoriesTable,
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) => MenuCategory.fromMap(maps[i]));
  }

  /// Add new menu category
  Future<int> addMenuCategory(MenuCategory category) async {
    final db = await database;
    return await db.insert(AppConstants.menuCategoriesTable, category.toMap());
  }

  /// Update menu category
  Future<int> updateMenuCategory(MenuCategory category) async {
    final db = await database;
    return await db.update(
      AppConstants.menuCategoriesTable,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete menu category
  /// Note: This might cause issues if items depend on it.
  /// For this simple POS, we will allow it but items might need re-categorization logic in real world.
  Future<int> deleteMenuCategory(int categoryId) async {
    final db = await database;
    // Optional: Delete all items in this category or move them to a default one
    // For now, we just delete the category.
    return await db.delete(
      AppConstants.menuCategoriesTable,
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Get menu items by category
  Future<List<MenuItem>> getMenuItemsByCategory(int categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.menuItemsTable,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => MenuItem.fromMap(maps[i]));
  }

  /// Get all menu items
  Future<List<MenuItem>> getAllMenuItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.menuItemsTable,
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => MenuItem.fromMap(maps[i]));
  }

  /// Add new menu item
  Future<int> addMenuItem(MenuItem item) async {
    final db = await database;
    return await db.insert(AppConstants.menuItemsTable, item.toMap());
  }

  /// Update menu item
  Future<int> updateMenuItem(MenuItem item) async {
    final db = await database;
    return await db.update(
      AppConstants.menuItemsTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete menu item
  Future<int> deleteMenuItem(int itemId) async {
    final db = await database;
    return await db.delete(
      AppConstants.menuItemsTable,
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ==================== ORDER MANAGEMENT ====================

  /// Get current active order for a table
  Future<Order?> getCurrentOrderForTable(int tableId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.ordersTable,
      where: 'table_id = ? AND status = ?',
      whereArgs: [tableId, AppConstants.orderOpen],
    );
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  /// Get order by ID
  Future<Order?> getOrder(int orderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.ordersTable,
      where: 'id = ?',
      whereArgs: [orderId],
    );
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  /// Get all items in an order (with menu item names)
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    // Join with menu_items to get item names
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT oi.*, mi.name as menu_item_name
      FROM ${AppConstants.orderItemsTable} oi
      LEFT JOIN ${AppConstants.menuItemsTable} mi ON oi.menu_item_id = mi.id
      WHERE oi.order_id = ?
    ''', [orderId]);
    return List.generate(maps.length, (i) => OrderItem.fromMap(maps[i]));
  }

  /// Add item to current order
  /// Snaps the price at the moment to prevent future price changes
  Future<int> addItemToOrder({
    required int orderId,
    required int menuItemId,
    required int quantity,
    required double priceAtMoment,
  }) async {
    final db = await database;

    // Check if item already exists in order, if so update quantity
    final existing = await db.query(
      AppConstants.orderItemsTable,
      where: 'order_id = ? AND menu_item_id = ? AND price_at_moment = ?',
      whereArgs: [orderId, menuItemId, priceAtMoment],
    );

    if (existing.isNotEmpty) {
      final currentQty = existing.first['quantity'] as int;
      final itemId = existing.first['id'] as int;
      return await db.update(
        AppConstants.orderItemsTable,
        {'quantity': currentQty + quantity},
        where: 'id = ?',
        whereArgs: [itemId],
      );
    }

    return await db.insert(
      AppConstants.orderItemsTable,
      {
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'quantity': quantity,
        'price_at_moment': priceAtMoment,
      },
    );
  }

  /// Remove item from order (decrement quantity or delete)
  Future<int> removeItemFromOrder(int orderItemId) async {
    final db = await database;
    final item = await db.query(
      AppConstants.orderItemsTable,
      where: 'id = ?',
      whereArgs: [orderItemId],
    );

    if (item.isEmpty) return 0;

    final quantity = item.first['quantity'] as int;
    if (quantity > 1) {
      // Decrement quantity
      return await db.update(
        AppConstants.orderItemsTable,
        {'quantity': quantity - 1},
        where: 'id = ?',
        whereArgs: [orderItemId],
      );
    } else {
      // Delete the item
      return await db.delete(
        AppConstants.orderItemsTable,
        where: 'id = ?',
        whereArgs: [orderItemId],
      );
    }
  }

  // ==================== CHECKOUT & PAYMENT ====================

  /// Calculate gross total amount for an order (before discount)
  Future<double> calculateOrderGrossTotal(int orderId) async {
    final order = await getOrder(orderId);
    if (order == null) return 0.0;

    final orderItems = await getOrderItems(orderId);

    // Calculate buffet charge: (adults + children) * tier price
    final totalHeadcount = order.adultHeadcount + order.childHeadcount;
    final buffetCharge = totalHeadcount * order.buffetTierPrice;

    // Calculate extra charges from a la carte items
    double extraCharges = 0.0;
    for (final item in orderItems) {
      extraCharges += (item.priceAtMoment * item.quantity);
    }

    return buffetCharge + extraCharges;
  }

  /// Calculate net total amount (after discount)
  Future<double> calculateOrderTotal(int orderId) async {
    double total = await calculateOrderGrossTotal(orderId);
    final order = await getOrder(orderId);

    if (order != null && order.promotionId != null) {
      final promotion = await getPromotion(order.promotionId!);
      if (promotion != null) {
        final type = promotion['discount_type'] as String;
        final value = promotion['discount_value'] as double;
        double discount = 0;
        if (type == 'PERCENT') {
          discount = total * (value / 100);
        } else {
          discount = value;
        }
        total -= discount;
        if (total < 0) total = 0.0;
      }
    }

    // Round to nearest integer as per requirement
    return total.roundToDouble();
  }

  /// Complete order checkout
  /// Saves total amount, payment method, and creates transaction record
  Future<int> checkoutOrder({
    required int orderId,
    required String paymentMethod,
    double? amountReceived,
    int? customerId,
    int pointsEarned = 0,
  }) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Calculate final total
      final order = await txn.query(
        AppConstants.ordersTable,
        where: 'id = ?',
        whereArgs: [orderId],
      );

      if (order.isEmpty) throw Exception('Order not found');
      final orderData = order.first;

      final adultCount = orderData['adult_headcount'] as int;
      final childCount = orderData['child_headcount'] as int;
      final buffetPrice = orderData['buffet_tier_price'] as double;
      final tableId = orderData['table_id'] as int?;

      // Get order items
      final items = await txn.query(
        AppConstants.orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      // Calculate extra charges
      double extraCharges = 0.0;
      for (final item in items) {
        extraCharges +=
            (item['price_at_moment'] as double) * (item['quantity'] as int);
      }

      // Calculate total (Gross)
      double totalAmount =
          ((adultCount + childCount) * buffetPrice) + extraCharges;

      // Calculate Discount
      double discountAmount = 0.0;
      final promotionId = orderData['promotion_id'] as int?;
      if (promotionId != null) {
        final promoRes = await txn
            .query(AppConstants.promotionsTable, where: 'id = ?', whereArgs: [promotionId]);
        if (promoRes.isNotEmpty) {
          final promo = promoRes.first;
          final type = promo['discount_type'] as String;
          final value = promo['discount_value'] as double;
          if (type == 'PERCENT') {
            discountAmount = totalAmount * (value / 100);
          } else {
            discountAmount = value;
          }
        }
      }

      // Net Total
      totalAmount -= discountAmount;
      if (totalAmount < 0) totalAmount = 0.0;

      // Round to nearest integer as per requirement
      totalAmount = totalAmount.roundToDouble();

      final changeAmount =
          amountReceived != null ? (amountReceived - totalAmount) : 0.0;

      // Build update map with required fields
      final updateMap = <String, dynamic>{
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'amount_received': amountReceived,
        'status': AppConstants.orderCompleted,
        'end_time': DateTime.now().millisecondsSinceEpoch,
        'discount_amount': discountAmount,
      };

      // Try to add optional fields if columns exist (for databases that have been migrated)
      // Check if columns exist by querying table info
      try {
        final tableInfo = await txn.rawQuery(
          "PRAGMA table_info(${AppConstants.ordersTable})",
        );
        final hasCustomerId = tableInfo.any((col) => col['name'] == 'customer_id');
        final hasPointsEarned = tableInfo.any((col) => col['name'] == 'points_earned');

        if (hasCustomerId) {
          updateMap['customer_id'] = customerId;
        }
        if (hasPointsEarned) {
          updateMap['points_earned'] = pointsEarned;
        }
      } catch (e) {
        // If we can't check, just proceed without optional fields
      }

      // Update order
      await txn.update(
        AppConstants.ordersTable,
        updateMap,
        where: 'id = ?',
        whereArgs: [orderId],
      );

      // Update Customer Points if applicable
      if (customerId != null && pointsEarned > 0) {
        await txn.rawUpdate(
          'UPDATE ${AppConstants.customersTable} SET points = points + ? WHERE id = ?',
          [pointsEarned, customerId],
        );
      }

      // Create transaction record
      await txn.insert(AppConstants.transactionsTable, {
        'order_id': orderId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'amount_received': amountReceived,
        'change_amount': changeAmount,
        'transaction_time': DateTime.now().millisecondsSinceEpoch,
      });

      // Update table status if applicable (for dine-in)
      if (tableId != null) {
        await txn.update(
          AppConstants.tablesTable,
          {
            'status': AppConstants.tableCleaning, // Set to cleaning after payment
            'current_order_id': null,
          },
          where: 'id = ?',
          whereArgs: [tableId],
        );
      }

      return orderId;
    });
  }

  /// Get sales by category
  Future<List<Map<String, dynamic>>> getSalesByCategory(
      {int? startTime, int? endTime}) async {
    final db = await database;
    String whereClause = 'o.status = ?';
    List<dynamic> whereArgs = [AppConstants.orderCompleted];

    if (startTime != null && endTime != null) {
      whereClause += ' AND o.end_time BETWEEN ? AND ?';
      whereArgs.addAll([startTime, endTime]);
    }

    return await db.rawQuery('''
      SELECT c.name as category_name, SUM(oi.price_at_moment * oi.quantity) as total_sales, SUM(oi.quantity) as total_quantity
      FROM ${AppConstants.orderItemsTable} oi
      JOIN ${AppConstants.ordersTable} o ON oi.order_id = o.id
      JOIN ${AppConstants.menuItemsTable} m ON oi.menu_item_id = m.id
      JOIN ${AppConstants.menuCategoriesTable} c ON m.category_id = c.id
      WHERE $whereClause
      GROUP BY c.id
      ORDER BY total_sales DESC
    ''', whereArgs);
  }

  /// Get top selling items
  Future<List<Map<String, dynamic>>> getTopSellingItems(
      {int? startTime, int? endTime, int limit = 5}) async {
    final db = await database;
    String whereClause = 'o.status = ?';
    List<dynamic> whereArgs = [AppConstants.orderCompleted];

    if (startTime != null && endTime != null) {
      whereClause += ' AND o.end_time BETWEEN ? AND ?';
      whereArgs.addAll([startTime, endTime]);
    }

    return await db.rawQuery('''
      SELECT m.name as item_name, SUM(oi.quantity) as total_quantity, SUM(oi.price_at_moment * oi.quantity) as total_sales
      FROM ${AppConstants.orderItemsTable} oi
      JOIN ${AppConstants.ordersTable} o ON oi.order_id = o.id
      JOIN ${AppConstants.menuItemsTable} m ON oi.menu_item_id = m.id
      WHERE $whereClause
      GROUP BY m.id
      ORDER BY total_quantity DESC
      LIMIT $limit
    ''', whereArgs);
  }

  /// Get transaction history
  Future<List<Transaction>> getTransactionHistory({int? limit}) async {
    final db = await database;
    String query =
        'SELECT * FROM ${AppConstants.transactionsTable} ORDER BY transaction_time DESC';
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // ==================== SHIFT MANAGEMENT ====================

  /// Get current open shift (if any)
  Future<Map<String, dynamic>?> getCurrentShift() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.shiftsTable,
      where: 'status = ?',
      whereArgs: [AppConstants.shiftOpen],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Open a new shift
  Future<int> openShift(double startingCash) async {
    final db = await database;
    // Close any existing open shifts first (safety check)
    await db.update(
      AppConstants.shiftsTable,
      {
        'status': AppConstants.shiftClosed,
        'end_time': DateTime.now().millisecondsSinceEpoch
      },
      where: 'status = ?',
      whereArgs: [AppConstants.shiftOpen],
    );

    return await db.insert(AppConstants.shiftsTable, {
      'start_time': DateTime.now().millisecondsSinceEpoch,
      'starting_cash': startingCash,
      'status': AppConstants.shiftOpen,
    });
  }

  /// Close current shift
  Future<void> closeShift({
    required double actualCash,
    required double expectedCash,
  }) async {
    final db = await database;
    await db.update(
      AppConstants.shiftsTable,
      {
        'status': AppConstants.shiftClosed,
        'end_time': DateTime.now().millisecondsSinceEpoch,
        'actual_cash': actualCash,
        'expected_cash': expectedCash,
      },
      where: 'status = ?',
      whereArgs: [AppConstants.shiftOpen],
    );
  }

  /// Get sales total since a specific time
  Future<double> getSalesTotalSince(int startTime) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM ${AppConstants.ordersTable} WHERE status = ? AND end_time >= ?',
      [AppConstants.orderCompleted, startTime],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // ==================== UTILITY METHODS ====================

  /// Batch save layout changes (Tables & Objects) in a single transaction
  Future<void> saveLayoutBatch({
    required List<TableModel> tables,
    required List<LayoutObjectModel> objects,
    required List<int> deletedTableIds,
    required List<int> deletedObjectIds,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Deletions
      for (final id in deletedTableIds) {
        await txn.delete(
          AppConstants.tablesTable,
          where: 'id = ? AND status = ?',
          whereArgs: [id, AppConstants.tableAvailable],
        );
      }
      for (final id in deletedObjectIds) {
        await txn.delete(
          AppConstants.layoutObjectsTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // 2. Tables (Update only, assumption: creation happens immediately in UI for ID)
      // Actually, for better UX, we might want to handle new tables here too if we change logic.
      // For now, we stick to updating existing tables' layout.
      for (final table in tables) {
        await txn.update(
          AppConstants.tablesTable,
          {
            'x': table.x,
            'y': table.y,
            'width': table.width,
            'height': table.height,
            'rotation': table.rotation,
            'color': table.color,
            'shape': table.shape,
          },
          where: 'id = ?',
          whereArgs: [table.id],
        );
      }

      // 3. Layout Objects (Insert or Update)
      for (final obj in objects) {
        if (obj.id == null) {
          await txn.insert(AppConstants.layoutObjectsTable, obj.toMap());
        } else {
          await txn.update(
            AppConstants.layoutObjectsTable,
            obj.toMap(),
            where: 'id = ?',
            whereArgs: [obj.id],
          );
        }
      }
    });
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
      await db.delete(AppConstants.transactionsTable);
      await db.delete(AppConstants.orderItemsTable);
      await db.delete(AppConstants.ordersTable);
      await db.delete(AppConstants.menuItemsTable);
      await db.delete(AppConstants.menuCategoriesTable);
      await db.delete(AppConstants.tablesTable);
      await db.delete(AppConstants.shiftsTable);

    // Re-insert default data
    await _insertDefaultData(db);
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;

    final totalTablesResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.tablesTable}');
    final totalTables = totalTablesResult.first['count'] as int? ?? 0;

    final occupiedTablesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tablesTable} WHERE status = ${AppConstants.tableOccupied}',
    );
    final occupiedTables = occupiedTablesResult.first['count'] as int? ?? 0;

    final totalOrdersResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.ordersTable}');
    final totalOrders = totalOrdersResult.first['count'] as int? ?? 0;

    final totalRevenueResult = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM ${AppConstants.transactionsTable}',
    );
    final revenue = totalRevenueResult.first['total'] as double? ?? 0.0;

    return {
      'total_tables': totalTables,
      'occupied_tables': occupiedTables,
      'total_orders': totalOrders,
      'total_revenue': revenue,
    };
  }

  // ==================== MENU CATEGORY MANAGEMENT ====================

  /// Get all menu categories
  Future<List<Map<String, dynamic>>> getAllMenuCategories() async {
    final db = await database;
    return await db.query(AppConstants.menuCategoriesTable, orderBy: 'id ASC');
  }

  // ==================== BUFFET TIER MANAGEMENT ====================

  /// Get all buffet tiers
  Future<List<Map<String, dynamic>>> getAllBuffetTiers() async {
    final db = await database;
    return await db.query(AppConstants.buffetTiersTable, orderBy: 'price ASC');
  }

  /// Get active buffet tiers only
  Future<List<Map<String, dynamic>>> getActiveBuffetTiers() async {
    final db = await database;
    return await db.query(
      AppConstants.buffetTiersTable,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'price ASC',
    );
  }

  /// Add buffet tier
  Future<int> addBuffetTier(Map<String, dynamic> tier) async {
    final db = await database;
    return await db.insert(AppConstants.buffetTiersTable, tier);
  }

  /// Update buffet tier
  Future<int> updateBuffetTier(int id, Map<String, dynamic> tier) async {
    final db = await database;
    return await db.update(
      AppConstants.buffetTiersTable,
      tier,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete buffet tier
  Future<int> deleteBuffetTier(int id) async {
    final db = await database;
    return await db.delete(AppConstants.buffetTiersTable, where: 'id = ?', whereArgs: [id]);
  }

  // ==================== PROMOTION MANAGEMENT ====================

  /// Get all promotions
  Future<List<Map<String, dynamic>>> getAllPromotions() async {
    final db = await database;
    return await db.query(AppConstants.promotionsTable, orderBy: 'name ASC');
  }

  /// Get active promotions
  Future<List<Map<String, dynamic>>> getActivePromotions() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.query(
      AppConstants.promotionsTable,
      where:
          'is_active = ? AND (start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)',
      whereArgs: [1, now, now],
      orderBy: 'name ASC',
    );
  }

  /// Add promotion
  Future<int> addPromotion(Map<String, dynamic> promotion) async {
    final db = await database;
    return await db.insert(AppConstants.promotionsTable, promotion);
  }

  /// Update promotion
  Future<int> updatePromotion(int id, Map<String, dynamic> promotion) async {
    final db = await database;
    return await db.update(
      AppConstants.promotionsTable,
      promotion,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete promotion
  Future<int> deletePromotion(int id) async {
    final db = await database;
    return await db.delete(AppConstants.promotionsTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Get specific promotion by ID
  Future<Map<String, dynamic>?> getPromotion(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.promotionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Apply promotion to order
  Future<int> applyPromotionToOrder(int orderId, int? promotionId) async {
    final db = await database;
    return await db.update(
      AppConstants.ordersTable,
      {'promotion_id': promotionId},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ---------------------------------------------------------------------------
  // Report Methods
  // ---------------------------------------------------------------------------
  // Customer Methods (Map-based for UI compatibility)
  // ---------------------------------------------------------------------------

  /// Search customers by name or phone
  Future<List<Map<String, dynamic>>> searchCustomers(String query,
      {int? limit, int? offset}) async {
    final db = await database;
    return await db.query(
      AppConstants.customersTable,
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    // Legacy support: Calling code expects List<Map>
  }

  /// Get all customers
  Future<List<Map<String, dynamic>>> getAllCustomers(
      {int? limit, int? offset}) async {
    final db = await database;
    return await db.query(
      AppConstants.customersTable,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// Add a new customer
  Future<int> addCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.insert(AppConstants.customersTable, customer);
  }

  /// Update customer details
  Future<int> updateCustomer(int id, Map<String, dynamic> customer) async {
    final db = await database;
    return await db.update(
      AppConstants.customersTable,
      customer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a customer
  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.customersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Order & Transaction Methods (Extensions)
  // ---------------------------------------------------------------------------

  /// Get detailed order items for a specific transaction (Legacy compatible)
  Future<List<Map<String, dynamic>>> getOrderDetails(int orderId) async {
    final db = await database;

    // 1. Get standard items
    final List<Map<String, dynamic>> items = List.from(await db.rawQuery('''
      SELECT 
        mi.name,
        oi.quantity,
        oi.price_at_moment as price,
        (oi.quantity * oi.price_at_moment) as total
      FROM ${AppConstants.orderItemsTable} oi
      JOIN ${AppConstants.menuItemsTable} mi ON oi.menu_item_id = mi.id
      WHERE oi.order_id = ?
    ''', [orderId]));

    // 2. Get Order Header for Buffet details
    final orderRes = await db.query(
      AppConstants.ordersTable,
      columns: ['adult_headcount', 'child_headcount', 'buffet_tier_price'],
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (orderRes.isNotEmpty) {
      final order = orderRes.first;
      final adults = order['adult_headcount'] as int? ?? 0;
      final children = order['child_headcount'] as int? ?? 0;
      final tierPrice = order['buffet_tier_price'] as double? ?? 0.0;

      if (adults > 0) {
        items.insert(0, {
          'name': 'Buffet (Adult)',
          'quantity': adults,
          'price': tierPrice,
          'total': adults * tierPrice,
        });
      }

      if (children > 0) {
        items.insert(1, {
          'name': 'Buffet (Child)',
          'quantity': children,
          'price': tierPrice,
          'total': children * tierPrice,
        });
      }
    }

    return items;
  }

  /// Get recent transactions (Map-based for Reports Screen)
  Future<List<Map<String, dynamic>>> getRecentTransactions(
      {int limit = 10, int offset = 0, int? startTime, int? endTime}) async {
    final db = await database;
    List<dynamic> args = [];
    String whereClause = '';

    if (startTime != null && endTime != null) {
      whereClause = 'WHERE t.transaction_time >= ? AND t.transaction_time <= ?';
      args = [startTime, endTime];
    }

    args.add(limit);
    args.add(offset);

    final sql = '''
      SELECT 
        t.id, 
        t.total_amount, 
        t.transaction_time,
        t.payment_method,
        t.order_id,
        tb.table_name,
        (SELECT COUNT(*) FROM ${AppConstants.orderItemsTable} oi WHERE oi.order_id = t.order_id) as item_count
      FROM ${AppConstants.transactionsTable} t
      JOIN ${AppConstants.ordersTable} o ON t.order_id = o.id
      LEFT JOIN ${AppConstants.tablesTable} tb ON o.table_id = tb.id
      $whereClause
      ORDER BY t.transaction_time DESC
      LIMIT ? OFFSET ?
    ''';

    final finalSql = sql.replaceFirst('\$whereClause', whereClause);
    return await db.rawQuery(finalSql, args);
  }

  // ---------------------------------------------------------------------------
  // Report Methods
  // ---------------------------------------------------------------------------

  /// Get sales summary for a date range (int timestamps)
  Future<Map<String, dynamic>> getSalesSummary(
      {int? startTime, int? endTime}) async {
    final db = await database;
    String whereClause = 'status = ?';
    List<dynamic> whereArgs = [AppConstants.orderCompleted];

    if (startTime != null && endTime != null) {
      whereClause += ' AND end_time BETWEEN ? AND ?';
      whereArgs.add(startTime);
      whereArgs.add(endTime);
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_orders,
        SUM(total_amount) as total_sales,
        AVG(total_amount) as average_order_value
      FROM ${AppConstants.ordersTable}
      WHERE $whereClause
    ''', whereArgs);

    if (result.isNotEmpty) {
      return {
        'total_orders': (result.first['total_orders'] as num?)?.toInt() ?? 0,
        'total_sales': (result.first['total_sales'] as num?)?.toDouble() ?? 0.0,
        'average_order_value':
            (result.first['average_order_value'] as num?)?.toDouble() ?? 0.0,
        // Also support camelCase if needed, but legacy likely used snake_case or specific keys
        // Reports screen uses: total_sales, total_orders. (Line 72/73 reports_screen.dart)
      };
    }
    return {'total_orders': 0, 'total_sales': 0.0, 'average_order_value': 0.0};
  }

  /// Get hourly sales for a specific date range
  Future<List<Map<String, dynamic>>> getHourlySales(
      int startTime, int endTime) async {
    final db = await database;

    // Use sqlite strftime to group by hour
    final result = await db.rawQuery('''
      SELECT 
        strftime('%H', end_time / 1000, 'unixepoch', 'localtime') as hour,
        SUM(total_amount) as total
      FROM ${AppConstants.ordersTable}
      WHERE status = ? AND end_time BETWEEN ? AND ?
      GROUP BY hour
      ORDER BY hour ASC
    ''', [AppConstants.orderCompleted, startTime, endTime]);

    return result;
  }

  /// Get top selling categories
  Future<List<Map<String, dynamic>>> getTopSellingCategories(
      {int? startTime, int? endTime, int limit = 5}) async {
    final db = await database;

    String dateFilter = '';
    List<dynamic> args = [];

    // Status must be completed
    args.add(AppConstants.orderCompleted);

    if (startTime != null && endTime != null) {
      dateFilter = 'AND o.end_time BETWEEN ? AND ?';
      args.add(startTime);
      args.add(endTime);
    }
    args.add(limit);

    final result = await db.rawQuery('''
      SELECT 
        c.name as category_name,
        SUM(oi.quantity * oi.price_at_moment) as total_sales,
        SUM(oi.quantity) as total_quantity
      FROM ${AppConstants.orderItemsTable} oi
      JOIN ${AppConstants.menuItemsTable} mi ON oi.menu_item_id = mi.id
      JOIN ${AppConstants.menuCategoriesTable} c ON mi.category_id = c.id
      JOIN ${AppConstants.ordersTable} o ON oi.order_id = o.id
      WHERE o.status = ? $dateFilter
      GROUP BY c.id
      ORDER BY total_sales DESC
      LIMIT ?
    ''', args);

    return result;
  }

  // ==================== DATABASE MANAGEMENT ====================

  /// Close database connection

}
