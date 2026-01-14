# TioRes - Customer Web Ordering System

## Overview
A mobile-first responsive web ordering system that integrates with the TioRes POS.

## Setup

### Requirements
- PHP 7.4+ with PDO extension
- MySQL/MariaDB database
- Web server (Apache/Nginx)

### Database Configuration
Edit `api/config.php`:
```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'respos');
define('DB_USER', 'root');
define('DB_PASS', 'your_password');
```

### API Key (Optional)
Set an API key for authentication:
```php
define('API_KEY', 'your_secret_key');
```

## Usage

### QR Code URL Format
Generate QR codes with these URL parameters:
```
https://your-domain.com/php-orders/?table=1&name=T1&tier=2
```

Parameters:
- `table` or `t`: Table ID
- `name` or `n`: Table display name
- `tier`: Buffet tier ID (optional)
- `order`: Existing order ID (optional)

## Pages

| Page | Description |
|------|-------------|
| `index.html` | Menu browsing and cart management |
| `orders.html` | Review and send orders to kitchen |
| `bill.html` | View bill and payment options |

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `get_items.php` | GET | Fetch menu items |
| `send_orders.php` | POST | Submit orders |
| `check_bill.php` | GET | Get bill summary |
| `update_items.php` | PUT | Sync menu from POS |
| `delete_items.php` | DELETE | Remove items from POS |
| `get_table_status.php` | GET | Table info |

## Features
- 📱 Mobile-first responsive design
- 🌙 Dark glassmorphism theme
- 🛒 Local cart management
- 🔄 Real-time order status
- 💳 PromptPay QR support (optional)
