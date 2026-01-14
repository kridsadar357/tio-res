<?php
/**
 * Database Configuration - PDO MySQL Connection
 * php-orders API
 */

// Database credentials
define('DB_HOST', 'localhost');
define('DB_NAME', 'respos');
define('DB_USER', 'root');
define('DB_PASS', 'Tar35700');
define('DB_CHARSET', 'utf8mb4');

// API Key for authentication (optional)
define('API_KEY', ''); // Set your API key here

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

/**
 * Create PDO connection
 * @return PDO
 */
function getConnection(): PDO {
    $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ];

    try {
        return new PDO($dsn, DB_USER, DB_PASS, $options);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Database connection failed', 'message' => $e->getMessage()]);
        exit();
    }
}

/**
 * Validate API Key if configured
 */
function validateApiKey(): void {
    if (empty(API_KEY)) return;

    $headers = getallheaders();
    $providedKey = $headers['X-API-Key'] ?? $_GET['api_key'] ?? '';

    if ($providedKey !== API_KEY) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized', 'message' => 'Invalid API key']);
        exit();
    }
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
