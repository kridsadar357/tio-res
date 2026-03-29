<?php
/**
 * GET /api/get_table_status.php
 * Returns table status and current order info (store-specific)
 * PUBLIC ACCESS - Customers can check table status
 * 
 * Query params:
 * - table_id: Table ID (required)
 */

require_once 'config.php';
$storeId = validatePublicAccess();

try {
    $pdo = getConnection();

    if (empty($_GET['table_id'])) {
        sendResponse(['error' => 'Missing required parameter: table_id'], 400);
    }

    $tableId = (int)$_GET['table_id'];

    // Get table info (with store filter)
    $tableStmt = $pdo->prepare("
        SELECT id, table_name, seats, status, current_order_id
        FROM tables 
        WHERE id = :table_id AND store_id = :store_id
    ");
    $tableStmt->execute([':table_id' => $tableId, ':store_id' => $storeId]);
    $table = $tableStmt->fetch();

    if (!$table) {
        sendResponse(['error' => 'Table not found'], 404);
    }

    // Get current order if exists
    $order = null;

    if ($table['current_order_id']) {
        $orderStmt = $pdo->prepare("
            SELECT id, total_amount, status, created_at, guest_count, adult_count, child_count
            FROM orders 
            WHERE id = :order_id AND store_id = :store_id
        ");
        $orderStmt->execute([':order_id' => $table['current_order_id'], ':store_id' => $storeId]);
        $order = $orderStmt->fetch();

        if ($order) {
            // Get order items count
            $countStmt = $pdo->prepare("
                SELECT COUNT(*) as count, SUM(quantity) as total_qty
                FROM order_items 
                WHERE order_id = :order_id
            ");
            $countStmt->execute([':order_id' => $order['id']]);
            $counts = $countStmt->fetch();
            $order['item_count'] = $counts['count'];
            $order['total_quantity'] = $counts['total_qty'];
        }
    }

    // Get buffet tier if applicable
    $buffetTier = null;
    if ($order) {
        $tierStmt = $pdo->prepare("
            SELECT bt.id, bt.name, bt.name_th, bt.price 
            FROM orders o
            JOIN buffet_tiers bt ON o.buffet_tier_id = bt.id
            WHERE o.id = :order_id AND bt.store_id = :store_id
        ");
        $tierStmt->execute([':order_id' => $order['id'], ':store_id' => $storeId]);
        $buffetTier = $tierStmt->fetch();
    }

    // Get store info
    $store = getStoreInfo();

    sendResponse([
        'success' => true,
        'store' => [
            'name' => $store['name'],
            'name_th' => $store['name_th']
        ],
        'table' => [
            'id' => $table['id'],
            'name' => $table['table_name'],
            'seats' => $table['seats'],
            'status' => $table['status'],
            'status_text' => ['available', 'occupied', 'cleaning'][$table['status']] ?? 'unknown'
        ],
        'order' => $order,
        'buffet_tier' => $buffetTier
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
