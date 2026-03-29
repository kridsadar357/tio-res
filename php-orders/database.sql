-- =====================================================
-- TioRes Web Ordering System - MariaDB Database Schema
-- Multi-Store Support with API Key Authentication
-- Compatible with MariaDB 10.3+ / MySQL 5.7+
-- =====================================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS `respos` 
    DEFAULT CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE `respos`;

-- =====================================================
-- DROP EXISTING TABLES (for clean install)
-- =====================================================
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `menu_items`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `buffet_tiers`;
DROP TABLE IF EXISTS `tables`;
DROP TABLE IF EXISTS `shifts`;
DROP TABLE IF EXISTS `store_settings`;
DROP TABLE IF EXISTS `stores`;

-- =====================================================
-- STORES TABLE (Multi-tenant support)
-- Each store has unique API key for authentication
-- =====================================================
CREATE TABLE `stores` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(200) NOT NULL COMMENT 'Store/Restaurant name',
    `name_th` VARCHAR(200) DEFAULT NULL COMMENT 'Store name (Thai)',
    `api_key` VARCHAR(64) NOT NULL COMMENT 'Unique API key for this store',
    `address` TEXT DEFAULT NULL,
    `tel` VARCHAR(50) DEFAULT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    `logo_url` VARCHAR(500) DEFAULT NULL,
    `timezone` VARCHAR(50) DEFAULT 'Asia/Bangkok',
    `currency` VARCHAR(10) DEFAULT 'THB',
    `tax_rate` DECIMAL(5,2) DEFAULT 7.00 COMMENT 'Tax percentage',
    `promptpay_id` VARCHAR(50) DEFAULT NULL COMMENT 'PromptPay for payment',
    `is_active` TINYINT(1) DEFAULT 1,
    `subscription_expires` DATE DEFAULT NULL COMMENT 'Subscription end date',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_api_key` (`api_key`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- CATEGORIES TABLE
-- Menu item categories (per store)
-- =====================================================
CREATE TABLE `categories` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL COMMENT 'Category name (Thai default)',
    `name_en` VARCHAR(100) DEFAULT NULL COMMENT 'Category name (English)',
    `name_th` VARCHAR(100) DEFAULT NULL COMMENT 'Category name (Thai)',
    `name_cn` VARCHAR(100) DEFAULT NULL COMMENT 'Category name (Chinese)',
    `description` TEXT DEFAULT NULL,
    `sort_order` INT DEFAULT 0 COMMENT 'Display order',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_store` (`store_id`),
    INDEX `idx_sort_order` (`sort_order`),
    INDEX `idx_is_active` (`is_active`),
    CONSTRAINT `fk_category_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- BUFFET TIERS TABLE
-- Different buffet pricing tiers (per store)
-- =====================================================
CREATE TABLE `buffet_tiers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL COMMENT 'Tier name (e.g., Standard, Premium)',
    `name_th` VARCHAR(100) DEFAULT NULL COMMENT 'Tier name (Thai)',
    `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Price per person',
    `description` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `sort_order` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_store` (`store_id`),
    INDEX `idx_is_active` (`is_active`),
    CONSTRAINT `fk_tier_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- MENU ITEMS TABLE
-- All menu items available for ordering (per store)
-- =====================================================
CREATE TABLE `menu_items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(200) NOT NULL COMMENT 'Item name (Thai default)',
    `name_en` VARCHAR(200) DEFAULT NULL COMMENT 'Item name (English)',
    `name_th` VARCHAR(200) DEFAULT NULL COMMENT 'Item name (Thai)',
    `name_cn` VARCHAR(200) DEFAULT NULL COMMENT 'Item name (Chinese)',
    `description` TEXT DEFAULT NULL,
    `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `image_url` VARCHAR(500) DEFAULT NULL COMMENT 'URL or path to item image',
    `category_id` INT UNSIGNED DEFAULT NULL,
    `buffet_tier_id` INT UNSIGNED DEFAULT NULL COMMENT 'NULL = available to all tiers',
    `is_available` TINYINT(1) DEFAULT 1,
    `is_extra_charge` TINYINT(1) DEFAULT 0 COMMENT 'Extra charge item (not included in buffet)',
    `sort_order` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_store` (`store_id`),
    INDEX `idx_category` (`category_id`),
    INDEX `idx_buffet_tier` (`buffet_tier_id`),
    INDEX `idx_available` (`is_available`),
    INDEX `idx_sort` (`sort_order`),
    CONSTRAINT `fk_menu_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_menu_category` FOREIGN KEY (`category_id`) 
        REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_menu_buffet_tier` FOREIGN KEY (`buffet_tier_id`) 
        REFERENCES `buffet_tiers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TABLES TABLE
-- Restaurant tables (per store)
-- =====================================================
CREATE TABLE `tables` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id` INT UNSIGNED NOT NULL,
    `table_name` VARCHAR(50) NOT NULL COMMENT 'Display name (e.g., Table 1, A1)',
    `seats` INT DEFAULT 4 COMMENT 'Number of seats',
    `status` TINYINT DEFAULT 0 COMMENT '0=available, 1=occupied, 2=cleaning',
    `current_order_id` INT UNSIGNED DEFAULT NULL COMMENT 'Current active order',
    `position_x` INT DEFAULT 0 COMMENT 'X position on floor plan',
    `position_y` INT DEFAULT 0 COMMENT 'Y position on floor plan',
    `zone` VARCHAR(50) DEFAULT NULL COMMENT 'Zone/section name',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_store_table` (`store_id`, `table_name`),
    INDEX `idx_store` (`store_id`),
    INDEX `idx_status` (`status`),
    CONSTRAINT `fk_table_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- SHIFTS TABLE
-- Daily shifts for reporting (per store)
-- =====================================================
CREATE TABLE `shifts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id` INT UNSIGNED NOT NULL,
    `opened_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `closed_at` TIMESTAMP NULL DEFAULT NULL,
    `opening_cash` DECIMAL(10,2) DEFAULT 0.00,
    `closing_cash` DECIMAL(10,2) DEFAULT NULL,
    `total_sales` DECIMAL(10,2) DEFAULT 0.00,
    `total_orders` INT DEFAULT 0,
    `notes` TEXT DEFAULT NULL,
    `status` ENUM('open', 'closed') DEFAULT 'open',
    PRIMARY KEY (`id`),
    INDEX `idx_store` (`store_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_opened` (`opened_at`),
    CONSTRAINT `fk_shift_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- ORDERS TABLE
-- Order headers (per store)
-- =====================================================
CREATE TABLE `orders` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id` INT UNSIGNED NOT NULL,
    `table_id` INT UNSIGNED DEFAULT NULL COMMENT 'NULL for takeaway orders',
    `buffet_tier_id` INT UNSIGNED DEFAULT NULL,
    `guest_count` INT DEFAULT 1,
    `adult_count` INT DEFAULT 0,
    `child_count` INT DEFAULT 0,
    `total_amount` DECIMAL(10,2) DEFAULT 0.00,
    `discount_amount` DECIMAL(10,2) DEFAULT 0.00,
    `discount_percent` DECIMAL(5,2) DEFAULT 0.00,
    `tax_amount` DECIMAL(10,2) DEFAULT 0.00,
    `net_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Total after discount and tax',
    `status` ENUM('open', 'completed', 'cancelled', 'pending') DEFAULT 'open',
    `source` ENUM('pos', 'web', 'takeaway') DEFAULT 'pos' COMMENT 'Order source',
    `payment_method` VARCHAR(50) DEFAULT NULL,
    `payment_status` ENUM('pending', 'paid', 'refunded') DEFAULT 'pending',
    `acknowledged` TINYINT(1) DEFAULT 0 COMMENT 'POS has received web order',
    `acknowledged_at` TIMESTAMP NULL DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `shift_id` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_store` (`store_id`),
    INDEX `idx_table` (`table_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_source` (`source`),
    INDEX `idx_acknowledged` (`acknowledged`),
    INDEX `idx_created` (`created_at`),
    INDEX `idx_payment_status` (`payment_status`),
    CONSTRAINT `fk_order_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_order_table` FOREIGN KEY (`table_id`) 
        REFERENCES `tables` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_order_buffet_tier` FOREIGN KEY (`buffet_tier_id`) 
        REFERENCES `buffet_tiers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_order_shift` FOREIGN KEY (`shift_id`) 
        REFERENCES `shifts` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add foreign key from tables to orders (after orders table exists)
ALTER TABLE `tables` 
    ADD CONSTRAINT `fk_table_order` FOREIGN KEY (`current_order_id`) 
    REFERENCES `orders` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- =====================================================
-- ORDER ITEMS TABLE
-- Individual items in an order
-- =====================================================
CREATE TABLE `order_items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` INT UNSIGNED NOT NULL,
    `menu_item_id` INT UNSIGNED NOT NULL,
    `quantity` INT NOT NULL DEFAULT 1,
    `price_at_moment` DECIMAL(10,2) NOT NULL COMMENT 'Price when ordered (snapshot)',
    `notes` VARCHAR(500) DEFAULT NULL COMMENT 'Special instructions',
    `status` ENUM('pending', 'acknowledged', 'preparing', 'served', 'cancelled') DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_order` (`order_id`),
    INDEX `idx_menu_item` (`menu_item_id`),
    INDEX `idx_status` (`status`),
    CONSTRAINT `fk_orderitem_order` FOREIGN KEY (`order_id`) 
        REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_orderitem_menu` FOREIGN KEY (`menu_item_id`) 
        REFERENCES `menu_items` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- STORE SETTINGS TABLE
-- Additional settings per store (key-value)
-- =====================================================
CREATE TABLE `store_settings` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id` INT UNSIGNED NOT NULL,
    `setting_key` VARCHAR(100) NOT NULL,
    `setting_value` TEXT DEFAULT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_store_key` (`store_id`, `setting_key`),
    INDEX `idx_store` (`store_id`),
    CONSTRAINT `fk_setting_store` FOREIGN KEY (`store_id`) 
        REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- VIEWS (Multi-store aware)
-- =====================================================

-- View: Active orders with table info (filtered by store)
CREATE OR REPLACE VIEW `v_active_orders` AS
SELECT 
    o.id AS order_id,
    o.store_id,
    o.table_id,
    t.table_name,
    o.total_amount,
    o.status,
    o.source,
    o.guest_count,
    o.created_at,
    COUNT(oi.id) AS item_count
FROM orders o
LEFT JOIN tables t ON o.table_id = t.id
LEFT JOIN order_items oi ON o.id = oi.order_id
WHERE o.status = 'open'
GROUP BY o.id;

-- View: Menu items with category (filtered by store)
CREATE OR REPLACE VIEW `v_menu_items` AS
SELECT 
    mi.id,
    mi.store_id,
    mi.name,
    mi.name_th,
    mi.price,
    mi.image_url,
    mi.is_available,
    mi.is_extra_charge,
    c.id AS category_id,
    c.name AS category_name,
    c.name_th AS category_name_th
FROM menu_items mi
LEFT JOIN categories c ON mi.category_id = c.id
ORDER BY c.sort_order, mi.sort_order, mi.name;

-- View: Pending web orders for POS polling (filtered by store)
CREATE OR REPLACE VIEW `v_pending_web_orders` AS
SELECT 
    o.id AS order_id,
    o.store_id,
    o.table_id,
    t.table_name,
    o.total_amount,
    o.created_at,
    o.source,
    COUNT(oi.id) AS item_count
FROM orders o
LEFT JOIN tables t ON o.table_id = t.id
LEFT JOIN order_items oi ON o.id = oi.order_id AND oi.status = 'pending'
WHERE o.source = 'web' 
  AND o.acknowledged = 0
  AND o.status = 'open'
GROUP BY o.id
ORDER BY o.created_at DESC;

-- =====================================================
-- STORED PROCEDURES (Multi-store aware)
-- =====================================================

DELIMITER //

-- Procedure: Calculate order total
CREATE PROCEDURE `sp_calculate_order_total`(IN p_order_id INT)
BEGIN
    UPDATE orders 
    SET total_amount = (
        SELECT COALESCE(SUM(oi.quantity * oi.price_at_moment), 0)
        FROM order_items oi
        WHERE oi.order_id = p_order_id
    ),
    updated_at = NOW()
    WHERE id = p_order_id;
END //

-- Procedure: Close table
CREATE PROCEDURE `sp_close_table`(IN p_table_id INT)
BEGIN
    -- Mark order as completed
    UPDATE orders 
    SET status = 'completed', 
        completed_at = NOW()
    WHERE table_id = p_table_id 
      AND status = 'open';
    
    -- Reset table status
    UPDATE tables 
    SET status = 2, -- cleaning
        current_order_id = NULL
    WHERE id = p_table_id;
END //

-- Function: Get store ID from API key
CREATE FUNCTION `fn_get_store_id`(p_api_key VARCHAR(64)) 
RETURNS INT UNSIGNED
DETERMINISTIC
BEGIN
    DECLARE v_store_id INT UNSIGNED;
    SELECT id INTO v_store_id 
    FROM stores 
    WHERE api_key = p_api_key 
      AND is_active = 1
    LIMIT 1;
    RETURN v_store_id;
END //

DELIMITER ;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Additional composite indexes for common queries
CREATE INDEX `idx_orders_store_status` ON `orders` (`store_id`, `status`);
CREATE INDEX `idx_orders_store_source` ON `orders` (`store_id`, `source`, `acknowledged`);
CREATE INDEX `idx_items_store_cat` ON `menu_items` (`store_id`, `category_id`, `is_available`);
CREATE INDEX `idx_tables_store_status` ON `tables` (`store_id`, `status`);

-- =====================================================
-- SAMPLE DATA (Demo Store)
-- =====================================================

-- Insert demo store with API key
INSERT INTO `stores` (`name`, `name_th`, `api_key`, `address`, `tel`, `tax_rate`, `currency`) VALUES
('TioRes Demo Restaurant', 'ร้านอาหารทดสอบ TioRes', 'demo_api_key_12345', '123 Demo Street, Bangkok 10110', '02-123-4567', 7.00, 'THB');

-- Get demo store ID
SET @demo_store_id = LAST_INSERT_ID();

-- Insert buffet tiers for demo store
INSERT INTO `buffet_tiers` (`store_id`, `name`, `name_th`, `price`, `description`, `sort_order`) VALUES
(@demo_store_id, 'Standard', 'มาตรฐาน', 299.00, 'Basic buffet package', 1),
(@demo_store_id, 'Premium', 'พรีเมี่ยม', 399.00, 'Premium buffet with seafood', 2),
(@demo_store_id, 'Deluxe', 'ดีลักซ์', 499.00, 'Deluxe buffet with premium meats', 3);

-- Insert categories for demo store
INSERT INTO `categories` (`store_id`, `name`, `name_th`, `sort_order`) VALUES
(@demo_store_id, 'Appetizers', 'อาหารเรียกน้ำย่อย', 1),
(@demo_store_id, 'Main Course', 'อาหารจานหลัก', 2),
(@demo_store_id, 'Seafood', 'อาหารทะเล', 3),
(@demo_store_id, 'Grilled', 'ปิ้งย่าง', 4),
(@demo_store_id, 'Noodles', 'เส้น', 5),
(@demo_store_id, 'Rice', 'ข้าว', 6),
(@demo_store_id, 'Soup', 'ซุป', 7),
(@demo_store_id, 'Dessert', 'ของหวาน', 8),
(@demo_store_id, 'Drinks', 'เครื่องดื่ม', 9),
(@demo_store_id, 'Extra', 'รายการพิเศษ', 10);

-- Get category IDs
SET @cat_appetizer = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Appetizers');
SET @cat_main = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Main Course');
SET @cat_seafood = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Seafood');
SET @cat_grilled = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Grilled');
SET @cat_noodles = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Noodles');
SET @cat_rice = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Rice');
SET @cat_soup = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Soup');
SET @cat_dessert = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Dessert');
SET @cat_drinks = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Drinks');
SET @cat_extra = (SELECT id FROM categories WHERE store_id = @demo_store_id AND name = 'Extra');

-- Insert sample menu items for demo store
INSERT INTO `menu_items` (`store_id`, `name`, `name_th`, `price`, `category_id`, `is_available`, `is_extra_charge`) VALUES
-- Appetizers
(@demo_store_id, 'Spring Rolls', 'ปอเปี๊ยะทอด', 0.00, @cat_appetizer, 1, 0),
(@demo_store_id, 'Chicken Satay', 'ไก่สะเต๊ะ', 0.00, @cat_appetizer, 1, 0),
(@demo_store_id, 'Crispy Pork', 'หมูกรอบ', 0.00, @cat_appetizer, 1, 0),

-- Main Course
(@demo_store_id, 'Pad Thai', 'ผัดไทย', 0.00, @cat_main, 1, 0),
(@demo_store_id, 'Fried Rice', 'ข้าวผัด', 0.00, @cat_main, 1, 0),
(@demo_store_id, 'Green Curry', 'แกงเขียวหวาน', 0.00, @cat_main, 1, 0),
(@demo_store_id, 'Red Curry', 'แกงแดง', 0.00, @cat_main, 1, 0),
(@demo_store_id, 'Stir-fried Basil', 'ผัดกะเพรา', 0.00, @cat_main, 1, 0),

-- Seafood
(@demo_store_id, 'Grilled Shrimp', 'กุ้งเผา', 0.00, @cat_seafood, 1, 0),
(@demo_store_id, 'Steamed Fish', 'ปลานึ่ง', 0.00, @cat_seafood, 1, 0),
(@demo_store_id, 'Squid Salad', 'ยำปลาหมึก', 0.00, @cat_seafood, 1, 0),

-- Grilled
(@demo_store_id, 'Pork Belly', 'หมูสามชั้น', 0.00, @cat_grilled, 1, 0),
(@demo_store_id, 'Beef Slice', 'เนื้อสไลด์', 0.00, @cat_grilled, 1, 0),
(@demo_store_id, 'Chicken Wings', 'ปีกไก่', 0.00, @cat_grilled, 1, 0),

-- Noodles
(@demo_store_id, 'Egg Noodles', 'บะหมี่', 0.00, @cat_noodles, 1, 0),
(@demo_store_id, 'Glass Noodles', 'วุ้นเส้น', 0.00, @cat_noodles, 1, 0),

-- Rice
(@demo_store_id, 'Steamed Rice', 'ข้าวสวย', 0.00, @cat_rice, 1, 0),
(@demo_store_id, 'Sticky Rice', 'ข้าวเหนียว', 0.00, @cat_rice, 1, 0),

-- Soup
(@demo_store_id, 'Tom Yum', 'ต้มยำ', 0.00, @cat_soup, 1, 0),
(@demo_store_id, 'Clear Soup', 'น้ำซุปใส', 0.00, @cat_soup, 1, 0),

-- Dessert
(@demo_store_id, 'Mango Sticky Rice', 'ข้าวเหนียวมะม่วง', 0.00, @cat_dessert, 1, 0),
(@demo_store_id, 'Ice Cream', 'ไอศกรีม', 0.00, @cat_dessert, 1, 0),

-- Drinks
(@demo_store_id, 'Water', 'น้ำเปล่า', 0.00, @cat_drinks, 1, 0),
(@demo_store_id, 'Soft Drink', 'น้ำอัดลม', 0.00, @cat_drinks, 1, 0),
(@demo_store_id, 'Thai Tea', 'ชาไทย', 0.00, @cat_drinks, 1, 0),

-- Extra charge items
(@demo_store_id, 'Premium Beef', 'เนื้อพรีเมี่ยม', 99.00, @cat_extra, 1, 1),
(@demo_store_id, 'Lobster', 'ล็อบสเตอร์', 299.00, @cat_extra, 1, 1),
(@demo_store_id, 'Imported Salmon', 'แซลมอนนำเข้า', 199.00, @cat_extra, 1, 1);

-- Insert sample tables for demo store
INSERT INTO `tables` (`store_id`, `table_name`, `seats`, `status`, `zone`) VALUES
(@demo_store_id, 'T1', 4, 0, 'Main'),
(@demo_store_id, 'T2', 4, 0, 'Main'),
(@demo_store_id, 'T3', 4, 0, 'Main'),
(@demo_store_id, 'T4', 6, 0, 'Main'),
(@demo_store_id, 'T5', 6, 0, 'Main'),
(@demo_store_id, 'A1', 2, 0, 'VIP'),
(@demo_store_id, 'A2', 2, 0, 'VIP'),
(@demo_store_id, 'B1', 8, 0, 'Group'),
(@demo_store_id, 'B2', 8, 0, 'Group'),
(@demo_store_id, 'Takeaway', 0, 0, 'Takeaway');

-- Insert default settings for demo store
INSERT INTO `store_settings` (`store_id`, `setting_key`, `setting_value`, `description`) VALUES
(@demo_store_id, 'receipt_header', 'Welcome to TioRes!', 'Receipt header text'),
(@demo_store_id, 'receipt_footer', 'Thank you for dining with us!', 'Receipt footer text'),
(@demo_store_id, 'enable_web_ordering', '1', 'Enable web ordering via QR'),
(@demo_store_id, 'auto_print_web_orders', '1', 'Auto print web orders at kitchen');

-- =====================================================
-- HELPER QUERIES FOR ADDING NEW STORES
-- =====================================================

-- To create a new store, run:
-- INSERT INTO stores (name, name_th, api_key, address, tel) VALUES
-- ('New Store Name', 'ชื่อร้านใหม่', 'unique_api_key_here', 'Address', 'Phone');
-- 
-- Then copy categories, menu items, tables from another store or create new ones

-- Generate a random API key (run in PHP or use this):
-- SELECT MD5(CONCAT(NOW(), RAND())) AS new_api_key;

-- =====================================================
-- COMPLETE!
-- =====================================================
-- Multi-store database schema created successfully.
-- 
-- Each store is identified by unique API key.
-- All data is isolated per store.
--
-- Demo store API key: demo_api_key_12345
-- 
-- Next steps:
-- 1. Update api/config.php to use store-based authentication
-- 2. Create your store with unique API key
-- 3. Configure API key in TioRes app settings
-- =====================================================
