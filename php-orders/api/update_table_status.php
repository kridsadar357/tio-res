<?php
/**
 * POST /api/update_table_status.php
 * Updates table status when POS opens/closes a table (store-specific)
 * 
 * Request body (JSON):
 * {
 *   "table_id": 6,
 *   "status": 1  // 0=available, 1=occupied, 2=cleaning
 * }
 */

require_once 'config.php';
$storeId = validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

try {
    $pdo = getConnection();
    $input = getJsonInput();

    // Validate required fields
    if (!isset($input['table_id']) || !isset($input['status'])) {
        sendResponse(['error' => 'Missing required fields: table_id, status'], 400);
    }

    $tableId = (int)$input['table_id'];
    $status = (int)$input['status'];

    // Validate status value
    if ($status < 0 || $status > 2) {
        sendResponse(['error' => 'Invalid status value. Must be 0 (available), 1 (occupied), or 2 (cleaning)'], 400);
    }

    // Verify table belongs to this store
    $checkStmt = $pdo->prepare("SELECT id FROM tables WHERE id = ? AND store_id = ?");
    $checkStmt->execute([$tableId, $storeId]);
    if (!$checkStmt->fetch()) {
        sendResponse(['error' => 'Table not found or access denied'], 404);
    }

    // Update table status
    $stmt = $pdo->prepare("UPDATE tables SET status = ?, updated_at = NOW() WHERE id = ? AND store_id = ?");
    $stmt->execute([$status, $tableId, $storeId]);

    $statusNames = ['available', 'occupied', 'cleaning'];
    
    sendResponse([
        'success' => true,
        'table_id' => $tableId,
        'status' => $status,
        'status_name' => $statusNames[$status] ?? 'unknown',
        'message' => 'Table status updated'
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
