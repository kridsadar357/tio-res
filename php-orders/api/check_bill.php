<?php
/**
 * GET /api/check_bill.php
 * Returns bill summary for a table
 * 
 * Query params:
 * - table_id: Table ID (required)
 * - order_id: Order ID (optional, uses latest open order if not provided)
 */

require_once 'config.php';
validateApiKey();

try {
    $pdo = getConnection();

    if (empty($_GET['table_id'])) {
        sendResponse(['error' => 'Missing required parameter: table_id'], 400);
    }

    $tableId = (int)$_GET['table_id'];
    $orderId = $_GET['order_id'] ?? null;

    // Get order
    if ($orderId) {
        $stmt = $pdo->prepare("SELECT * FROM orders WHERE id = :order_id");
        $stmt->execute([':order_id' => $orderId]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM orders WHERE table_id = :table_id AND status = 'open' ORDER BY created_at DESC LIMIT 1");
        $stmt->execute([':table_id' => $tableId]);
    }

    $order = $stmt->fetch();

    if (!$order) {
        sendResponse(['error' => 'No open order found for this table'], 404);
    }

    // Get order items with details
    $itemsStmt = $pdo->prepare("
        SELECT 
            oi.id, oi.quantity, oi.notes, oi.status,
            mi.name, mi.price,
            (oi.quantity * mi.price) as subtotal
        FROM order_items oi
        JOIN menu_items mi ON oi.menu_item_id = mi.id
        WHERE oi.order_id = :order_id
        ORDER BY oi.created_at
    ");
    $itemsStmt->execute([':order_id' => $order['id']]);
    $items = $itemsStmt->fetchAll();

    // Calculate totals
    $subtotal = array_sum(array_column($items, 'subtotal'));
    $discount = $order['discount_amount'] ?? 0;
    $tax = 0; // Add tax calculation if needed
    $grandTotal = $subtotal - $discount + $tax;

    // Get table info
    $tableStmt = $pdo->prepare("SELECT table_name, seats FROM tables WHERE id = :table_id");
    $tableStmt->execute([':table_id' => $tableId]);
    $table = $tableStmt->fetch();

    sendResponse([
        'success' => true,
        'order_id' => $order['id'],
        'table' => $table,
        'items' => $items,
        'summary' => [
            'subtotal' => $subtotal,
            'discount' => $discount,
            'tax' => $tax,
            'grand_total' => $grandTotal,
            'item_count' => count($items)
        ],
        'status' => $order['status'],
        'created_at' => $order['created_at']
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
