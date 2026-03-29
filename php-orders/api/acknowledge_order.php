<?php
/**
 * POST /api/acknowledge_order.php
 * Marks an order as acknowledged by POS (store-specific)
 * 
 * Request body (JSON):
 * {"order_id": 123}
 */

require_once 'config.php';
$storeId = validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

try {
    $pdo = getConnection();
    $input = getJsonInput();

    if (empty($input['order_id'])) {
        sendResponse(['error' => 'Missing required field: order_id'], 400);
    }

    $orderId = (int)$input['order_id'];

    // Verify order belongs to this store
    $checkStmt = $pdo->prepare("SELECT id FROM orders WHERE id = :order_id AND store_id = :store_id");
    $checkStmt->execute([':order_id' => $orderId, ':store_id' => $storeId]);
    if (!$checkStmt->fetch()) {
        sendResponse(['error' => 'Order not found or access denied'], 404);
    }

    $stmt = $pdo->prepare("
        UPDATE orders 
        SET acknowledged = 1, acknowledged_at = NOW() 
        WHERE id = :order_id AND store_id = :store_id
    ");
    $stmt->execute([':order_id' => $orderId, ':store_id' => $storeId]);

    // Also mark all pending items as acknowledged
    $itemsStmt = $pdo->prepare("
        UPDATE order_items 
        SET status = 'acknowledged' 
        WHERE order_id = :order_id AND status = 'pending'
    ");
    $itemsStmt->execute([':order_id' => $orderId]);

    sendResponse([
        'success' => true,
        'order_id' => $orderId,
        'message' => 'รับออเดอร์แล้ว'
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
