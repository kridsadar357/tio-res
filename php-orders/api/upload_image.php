<?php
/**
 * Upload Image API
 * Uploads menu item images to server
 * 
 * Accepts: multipart/form-data with 'image' file and optional 'item_id'
 * Returns: { success: true, image_url: "https://..." }
 */

require_once 'config.php';
$storeId = validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

// Configuration
$uploadDir = __DIR__ . '/../uploads/menu/';
$allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
$maxSize = 5 * 1024 * 1024; // 5MB

// Create upload directory if not exists
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// Create store-specific directory
$storeDir = $uploadDir . 'store_' . $storeId . '/';
if (!file_exists($storeDir)) {
    mkdir($storeDir, 0755, true);
}

// Check if file was uploaded
if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    $errorMsg = 'No image uploaded';
    if (isset($_FILES['image'])) {
        switch ($_FILES['image']['error']) {
            case UPLOAD_ERR_INI_SIZE:
            case UPLOAD_ERR_FORM_SIZE:
                $errorMsg = 'File too large';
                break;
            case UPLOAD_ERR_NO_FILE:
                $errorMsg = 'No file selected';
                break;
            default:
                $errorMsg = 'Upload error: ' . $_FILES['image']['error'];
        }
    }
    sendResponse(['success' => false, 'error' => $errorMsg], 400);
}

$file = $_FILES['image'];

// Validate file type
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

if (!in_array($mimeType, $allowedTypes)) {
    sendResponse(['success' => false, 'error' => 'Invalid file type. Allowed: jpg, png, gif, webp'], 400);
}

// Validate file size
if ($file['size'] > $maxSize) {
    sendResponse(['success' => false, 'error' => 'File too large. Max: 5MB'], 400);
}

// Generate unique filename
$extension = pathinfo($file['name'], PATHINFO_EXTENSION);
if (empty($extension)) {
    $extension = explode('/', $mimeType)[1];
    if ($extension === 'jpeg') $extension = 'jpg';
}

$itemId = $_POST['item_id'] ?? '';
$filename = $itemId ? "item_{$itemId}" : 'img_' . time() . '_' . uniqid();
$filename .= '.' . $extension;

$targetPath = $storeDir . $filename;

// Move uploaded file
if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
    sendResponse(['success' => false, 'error' => 'Failed to save file'], 500);
}

// Generate public URL
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];
$basePath = dirname(dirname($_SERVER['SCRIPT_NAME'])); // Go up from /api to root
$imageUrl = $protocol . '://' . $host . $basePath . '/uploads/menu/store_' . $storeId . '/' . $filename;

// Update menu item if item_id provided
if (!empty($itemId)) {
    try {
        $pdo = getConnection();
        $stmt = $pdo->prepare("UPDATE menu_items SET image_url = :url WHERE id = :id AND store_id = :store_id");
        $stmt->execute([
            ':url' => $imageUrl,
            ':id' => $itemId,
            ':store_id' => $storeId
        ]);
    } catch (PDOException $e) {
        // Image uploaded but DB update failed - still return success with URL
        error_log("Failed to update menu_item image_url: " . $e->getMessage());
    }
}

sendResponse([
    'success' => true,
    'message' => 'Image uploaded successfully',
    'image_url' => $imageUrl,
    'filename' => $filename
]);
