<?php
/**
 * GET /api/get_table_status.php
 * Returns table status and current order info
 * 
 * Query params:
 * - table_id: Table ID (required)
 */

require_once 'config.php';
validateApiKey();

try {
    $pdo = getConnection();

    if (empty($_GET['table_id'])) {
        sendResponse(['error' => 'Missing required parameter: table_id'], 400);
    }

    $tableId = (int)$_GET['table_id'];

    // Get table info
    $tableStmt = $pdo->prepare("
        SELECT id, table_name, seats, status, current_order_id
        FROM tables 
        WHERE id = :table_id
    ");
    $tableStmt->execute([':table_id' => $tableId]);
    $table = $tableStmt->fetch();

    if (!$table) {
        sendResponse(['error' => 'Table not found'], 404);
    }

    // Get current order if exists
    $order = null;
    $orderItems = [];

    if ($table['current_order_id']) {
        $orderStmt = $pdo->prepare("
            SELECT id, total_amount, status, created_at, guest_count
            FROM orders 
            WHERE id = :order_id
        ");
        $orderStmt->execute([':order_id' => $table['current_order_id']]);
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
            SELECT bt.id, bt.name, bt.price 
            FROM orders o
            JOIN buffet_tiers bt ON o.buffet_tier_id = bt.id
            WHERE o.id = :order_id
        ");
        $tierStmt->execute([':order_id' => $order['id']]);
        $buffetTier = $tierStmt->fetch();
    }

    sendResponse([
        'success' => true,
        'table' => [
            'id' => $table['id'],
            'name' => $table['table_name'],
            'seats' => $table['seats'],
            'status' => $table['status'], // 0: available, 1: occupied, 2: cleaning
            'status_text' => ['available', 'occupied', 'cleaning'][$table['status']] ?? 'unknown'
        ],
        'order' => $order,
        'buffet_tier' => $buffetTier
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
