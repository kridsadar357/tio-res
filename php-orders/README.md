# TioRes - Customer Web Ordering System

## Overview
A multi-store, mobile-first responsive web ordering system that integrates with the TioRes POS.

## Multi-Store Architecture
Each store/restaurant has its own:
- Unique **API Key** for authentication
- Menu items and categories
- Tables and orders
- Settings and configurations

All data is isolated per store using the API key.

## Setup

### Requirements
- PHP 7.4+ with PDO extension
- MariaDB 10.3+ or MySQL 5.7+
- Web server (Apache/Nginx) with mod_rewrite enabled

### 1. Database Setup
```bash
# Import the database schema
mysql -u root -p < database.sql
```

This creates:
- `stores` - Store/restaurant profiles with API keys
- `categories` - Menu categories per store
- `menu_items` - Menu items per store
- `buffet_tiers` - Buffet pricing tiers per store
- `tables` - Restaurant tables per store
- `orders` - Order headers per store
- `order_items` - Order line items
- `shifts` - Daily shifts per store
- `store_settings` - Additional settings per store

### 2. Database Configuration
Edit `api/config.php`:
```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'respos');
define('DB_USER', 'your_user');
define('DB_PASS', 'your_password');
```

### 3. Create Your Store

**Option A: Auto-Registration (Recommended)**
Simply use any API key in the POS app. The system will automatically create a new store when you first sync data.

**Option B: Manual Creation**
```sql
-- Generate API key
SELECT MD5(CONCAT(NOW(), RAND(), 'your_store_name')) AS new_api_key;

-- Create store
INSERT INTO stores (name, name_th, api_key, address, tel) VALUES
('My Restaurant', 'ร้านอาหารของฉัน', 'generated_api_key_here', 'Address', '02-xxx-xxxx');
```

### 4. Configure TioRes App
1. Go to **Settings > API Settings**
2. Enable **API**
3. Set **Base URL**: `https://your-domain.com` (app will auto-add `/api`)
4. Set **API Key**: Your store's API key
5. Click **"Send All Data"** to sync categories, tables, menu items to server
6. Enable **QR Code Ordering** for customer self-ordering

## API Authentication

All API requests require the store's API key:

```bash
# Via Header (recommended)
curl -H "X-API-Key: your_api_key" https://your-domain.com/api/items

# Via Query Parameter
curl https://your-domain.com/api/items?api_key=your_api_key
```

## URL Structure

### Friendly URLs (for QR Codes)
| URL | Description |
|-----|-------------|
| `/open-table/1?name=T1&tier=2` | Open table QR (printed on receipt) |
| `/menu/1?name=T1` | Direct menu access |
| `/orders` | Order review page |
| `/bill` | Bill/payment page |

### Query Parameters
| Parameter | Description |
|-----------|-------------|
| `table` or `t` | Table ID (required) |
| `name` or `n` | Table display name |
| `tier` | Buffet tier ID |
| `order` | Existing order ID |
| `api_key` | Store API key (if not in header) |

## API Endpoints

### Menu & Items
| Endpoint | Method | Description |
|----------|--------|-------------|
| `api/get_items.php` | GET | Fetch menu items for store |
| `api/update_items.php` | PUT/POST | Create/update menu items |
| `api/delete_items.php` | DELETE | Remove menu items |

### Orders
| Endpoint | Method | Description |
|----------|--------|-------------|
| `api/send_orders.php` | POST | Submit new orders |
| `api/check_bill.php` | GET | Get bill summary |
| `api/get_pending_orders.php` | GET | Pending web orders for POS |
| `api/acknowledge_order.php` | POST | Mark order as received |

### Tables
| Endpoint | Method | Description |
|----------|--------|-------------|
| `api/get_table_status.php` | GET | Get table info and status |

### Initial Data Sync (from POS)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `api/sync_store_info.php` | POST | Sync store info from POS |
| `api/sync_categories.php` | POST | Sync all categories from POS |
| `api/sync_buffet_tiers.php` | POST | Sync buffet tiers from POS |
| `api/sync_tables.php` | POST | Sync tables from POS |
| `api/sync_menu_items.php` | POST | Sync all menu items from POS |
| `api/upload_image.php` | POST | Upload menu item images (multipart/form-data) |

### Clean API URLs (via .htaccess)
| Clean URL | Maps To |
|-----------|---------|
| `/api/items` | `api/get_items.php` |
| `/api/orders` | `api/send_orders.php` |
| `/api/bill` | `api/check_bill.php` |
| `/api/table` | `api/get_table_status.php` |
| `/api/pending` | `api/get_pending_orders.php` |
| `/api/acknowledge` | `api/acknowledge_order.php` |
| `/api/sync/categories` | `api/sync_categories.php` |
| `/api/sync/buffet-tiers` | `api/sync_buffet_tiers.php` |
| `/api/sync/tables` | `api/sync_tables.php` |
| `/api/sync/menu-items` | `api/sync_menu_items.php` |
| `/api/sync/store-info` | `api/sync_store_info.php` |
| `/api/upload-image` | `api/upload_image.php` |

## Apache Setup
The included `.htaccess` file handles URL rewriting:
1. Enable `mod_rewrite`: `a2enmod rewrite`
2. Set `AllowOverride All` in Apache config
3. Restart Apache

## Nginx Setup
```nginx
location / {
    try_files $uri $uri/ @rewrite;
}

location @rewrite {
    rewrite ^/open-table/([0-9]+)/?$ /index.html?table=$1 last;
    rewrite ^/menu/([0-9]+)/?$ /index.html?table=$1 last;
    rewrite ^/orders/?$ /orders.html last;
    rewrite ^/bill/?$ /bill.html last;
}

location /api/ {
    try_files $uri $uri/ =404;
}
```

## Integration with TioRes App

### QR Code Ordering Flow
1. Enable QR Ordering in app settings
2. Set Base URL (e.g., `https://tiores.example.com`)
3. Set API Key for your store
4. When opening a table, the receipt QR links to:
   ```
   https://tiores.example.com/open-table/{table_id}?name={table_name}&tier={tier_id}&api_key={key}
   ```
5. Customer scans QR → browses menu → orders
6. POS polls for pending orders and acknowledges

### Initial Data Sync (First-Time Setup)
When first setting up the API:
1. Go to **Settings > API Settings**
2. Enable API and enter Base URL and API Key
3. Click **"Send All Data"** button
4. This syncs:
   - All categories
   - All buffet tiers
   - All tables
   - All menu items
5. The web system will now have all your POS data

### Menu Sync
The app can sync menu items to the web system:
- New items are created with `store_id`
- Updates only affect items belonging to the store
- Deletions can be soft (disable) or hard (remove)

## Demo Store
The database includes a demo store:
- **API Key**: `demo_api_key_12345`
- Sample categories, menu items, and tables
- Use for testing before creating your real store

## Security Notes
1. Each store's API key provides complete data isolation
2. Store subscriptions can be controlled via `subscription_expires`
3. Stores can be disabled via `is_active` flag
4. All queries filter by `store_id` from the API key

## Features
- 📱 Mobile-first responsive design
- 🏪 Multi-store support with API key isolation
- 🌙 Dark glassmorphism theme
- 🛒 Local cart management
- 🔄 Real-time order status
- 💳 PromptPay QR support (per store)
- 🔒 API key authentication
- 🔗 Clean/friendly URLs
- 🌐 Thai language support