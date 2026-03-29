<?php
/**
 * Database Configuration - PDO MySQL Connection
 * Multi-Store Support with API Key Authentication
 */

// Database credentials
define('DB_HOST', 'localhost');
define('DB_NAME', 'respos');
define('DB_USER', 'root');
define('DB_PASS', 'your_password');
define('DB_CHARSET', 'utf8mb4');

// CORS Headers for frontend access
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Key');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Global store context
$GLOBALS['current_store_id'] = null;
$GLOBALS['current_store'] = null;

/**
 * Create PDO connection
 * @return PDO
 */
function getConnection(): PDO {
    static $pdo = null;
    
    if ($pdo === null) {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];

        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database connection failed', 'message' => $e->getMessage()]);
            exit();
        }
    }
    
    return $pdo;
}

/**
 * Validate API Key and get Store ID
 * Sets global store context
 * Auto-creates new store if API key doesn't exist (for first-time setup)
 * @param bool $required Whether API key is required
 * @return int|null Store ID
 */
function validateApiKey(bool $required = true): ?int {
    // Try multiple methods to get API key (some hosts strip custom headers)
    $apiKey = '';
    
    // Method 1: getallheaders() - works on Apache
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        $apiKey = $headers['X-API-Key'] ?? $headers['x-api-key'] ?? $headers['X-Api-Key'] ?? '';
    }
    
    // Method 2: $_SERVER with HTTP_ prefix (works on most servers)
    if (empty($apiKey)) {
        $apiKey = $_SERVER['HTTP_X_API_KEY'] ?? '';
    }
    
    // Method 3: Query parameter (fallback - always works)
    if (empty($apiKey)) {
        $apiKey = $_GET['api_key'] ?? $_POST['api_key'] ?? '';
    }
    
    // Method 4: JSON body (for POST requests)
    if (empty($apiKey) && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        $apiKey = $input['api_key'] ?? '';
    }
    
    if (empty($apiKey)) {
        if ($required) {
            http_response_code(401);
            echo json_encode([
                'error' => 'Unauthorized', 
                'message' => 'API key is required. Provide X-API-Key header or api_key parameter.'
            ]);
            exit();
        }
        return null;
    }
    
    try {
        $pdo = getConnection();
        $stmt = $pdo->prepare("
            SELECT id, name, name_th, address, tel, logo_url, 
                   currency, tax_rate, promptpay_id, is_active,
                   subscription_expires
            FROM stores 
            WHERE api_key = :api_key
            LIMIT 1
        ");
        $stmt->execute([':api_key' => $apiKey]);
        $store = $stmt->fetch();
        
        // Auto-create store if API key doesn't exist (first-time setup from POS)
        if (!$store) {
            $store = createStoreFromApiKey($apiKey);
            if (!$store) {
                http_response_code(500);
                echo json_encode(['error' => 'Server error', 'message' => 'Failed to create store']);
                exit();
            }
        }
        
        if (!$store['is_active']) {
            http_response_code(403);
            echo json_encode(['error' => 'Forbidden', 'message' => 'Store is inactive']);
            exit();
        }
        
        // Check subscription expiry
        if ($store['subscription_expires'] && strtotime($store['subscription_expires']) < time()) {
            http_response_code(403);
            echo json_encode(['error' => 'Forbidden', 'message' => 'Subscription expired']);
            exit();
        }
        
        // Set global store context
        $GLOBALS['current_store_id'] = (int)$store['id'];
        $GLOBALS['current_store'] = $store;
        
        return (int)$store['id'];
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Database error', 'message' => $e->getMessage()]);
        exit();
    }
}

/**
 * Create a new store from API key (auto-registration)
 * @param string $apiKey The API key to register
 * @return array|null Store data
 */
function createStoreFromApiKey(string $apiKey): ?array {
    try {
        $pdo = getConnection();
        
        // Generate a default store name from API key
        $storeName = 'Store_' . substr($apiKey, 0, 8);
        
        // Insert new store with 1 year subscription (using CURDATE for DATE column)
        $stmt = $pdo->prepare("
            INSERT INTO stores (api_key, name, name_th, is_active, subscription_expires)
            VALUES (:api_key, :name, :name_th, 1, DATE_ADD(CURDATE(), INTERVAL 1 YEAR))
        ");
        $stmt->execute([
            ':api_key' => $apiKey,
            ':name' => $storeName,
            ':name_th' => $storeName,
        ]);
        
        $storeId = $pdo->lastInsertId();
        
        if (!$storeId) {
            error_log("createStoreFromApiKey: lastInsertId returned 0");
            return null;
        }
        
        // Fetch the created store
        $stmt = $pdo->prepare("
            SELECT id, name, name_th, address, tel, logo_url, 
                   currency, tax_rate, promptpay_id, is_active,
                   subscription_expires
            FROM stores 
            WHERE id = :id
        ");
        $stmt->execute([':id' => $storeId]);
        
        $store = $stmt->fetch();
        error_log("createStoreFromApiKey: Created store ID $storeId for API key: " . substr($apiKey, 0, 8) . "...");
        
        return $store;
        
    } catch (PDOException $e) {
        error_log("createStoreFromApiKey failed: " . $e->getMessage());
        return null;
    }
}

/**
 * Get current store ID (after validation)
 * @return int
 */
function getStoreId(): int {
    if ($GLOBALS['current_store_id'] === null) {
        http_response_code(500);
        echo json_encode(['error' => 'Server error', 'message' => 'Store context not initialized']);
        exit();
    }
    return $GLOBALS['current_store_id'];
}

/**
 * Get current store info
 * @return array|null
 */
function getStoreInfo(): ?array {
    return $GLOBALS['current_store'];
}

/**
 * Get store ID from table ID (for public customer access)
 * @param int $tableId Table ID
 * @return int|null Store ID
 */
function getStoreIdFromTable(int $tableId): ?int {
    try {
        $pdo = getConnection();
        $stmt = $pdo->prepare("
            SELECT t.store_id, s.id, s.name, s.name_th, s.address, s.tel, s.logo_url, 
                   s.currency, s.tax_rate, s.is_active
            FROM tables t
            JOIN stores s ON t.store_id = s.id
            WHERE t.id = :table_id AND s.is_active = 1
            LIMIT 1
        ");
        $stmt->execute([':table_id' => $tableId]);
        $result = $stmt->fetch();
        
        if ($result) {
            $GLOBALS['current_store_id'] = (int)$result['store_id'];
            $GLOBALS['current_store'] = [
                'id' => $result['id'],
                'name' => $result['name'],
                'name_th' => $result['name_th'],
                'address' => $result['address'],
                'tel' => $result['tel'],
                'logo_url' => $result['logo_url'],
                'currency' => $result['currency'],
                'tax_rate' => $result['tax_rate'],
            ];
            return (int)$result['store_id'];
        }
        return null;
    } catch (PDOException $e) {
        error_log("getStoreIdFromTable failed: " . $e->getMessage());
        return null;
    }
}

/**
 * Validate public access (for customer-facing endpoints)
 * Uses table_id/table to determine store context
 * @return int|null Store ID
 */
function validatePublicAccess(): ?int {
    // First try API key (if admin is accessing)
    $storeId = validateApiKey(false);
    if ($storeId) {
        return $storeId;
    }
    
    // Try table_id or table for customer access (accept both parameter names)
    $tableId = (int)($_GET['table_id'] ?? $_GET['table'] ?? $_POST['table_id'] ?? $_POST['table'] ?? 0);
    if ($tableId > 0) {
        $storeId = getStoreIdFromTable($tableId);
        if ($storeId) {
            return $storeId;
        }
    }
    
    // No valid context found
    http_response_code(400);
    echo json_encode([
        'error' => 'Bad Request', 
        'message' => 'Either API key or table/table_id is required for store identification.'
    ]);
    exit();
}

/**
 * Send JSON response
 * @param mixed $data Response data
 * @param int $code HTTP status code
 */
function sendResponse($data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

/**
 * Get JSON input from request body
 * @return array
 */
function getJsonInput(): array {
    $input = file_get_contents('php://input');
    return json_decode($input, true) ?? [];
}

/**
 * Log API request (optional - for debugging)
 */
function logRequest(): void {
    $logFile = __DIR__ . '/../logs/api_' . date('Y-m-d') . '.log';
    $logData = [
        'time' => date('Y-m-d H:i:s'),
        'method' => $_SERVER['REQUEST_METHOD'],
        'uri' => $_SERVER['REQUEST_URI'],
        'store_id' => $GLOBALS['current_store_id'],
        'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
    ];
    @file_put_contents($logFile, json_encode($logData) . "\n", FILE_APPEND);
}
