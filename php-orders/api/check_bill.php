<?php
/**
 * GET /api/check_bill.php
 * Returns bill summary for a table (store-specific)
 * PUBLIC ACCESS - Customers can check their bill
 * 
 * Query params:
 * - table_id: Table ID (required)
 * - order_id: Order ID (optional, uses latest open order if not provided)
 */

require_once 'config.php';
$storeId = validatePublicAccess();

try {
    $pdo = getConnection();

    if (empty($_GET['table_id'])) {
        sendResponse(['error' => 'Missing required parameter: table_id'], 400);
    }

    $tableId = (int)$_GET['table_id'];
    $orderId = $_GET['order_id'] ?? null;

    // Get order (with store filter)
    if ($orderId) {
        $stmt = $pdo->prepare("
            SELECT * FROM orders 
            WHERE id = :order_id AND store_id = :store_id
        ");
        $stmt->execute([':order_id' => $orderId, ':store_id' => $storeId]);
    } else {
        $stmt = $pdo->prepare("
            SELECT * FROM orders 
            WHERE table_id = :table_id AND store_id = :store_id AND status = 'open' 
            ORDER BY created_at DESC LIMIT 1
        ");
        $stmt->execute([':table_id' => $tableId, ':store_id' => $storeId]);
    }

    $order = $stmt->fetch();

    if (!$order) {
        sendResponse(['error' => 'No open order found for this table'], 404);
    }

    // Get order items with details
    $itemsStmt = $pdo->prepare("
        SELECT 
            oi.id, oi.quantity, oi.notes, oi.status, oi.price_at_moment,
            mi.name, mi.name_th,
            (oi.quantity * oi.price_at_moment) as subtotal
        FROM order_items oi
        JOIN menu_items mi ON oi.menu_item_id = mi.id
        WHERE oi.order_id = :order_id
        ORDER BY oi.created_at
    ");
    $itemsStmt->execute([':order_id' => $order['id']]);
    $items = $itemsStmt->fetchAll();

    // Get store info for tax calculation
    $store = getStoreInfo();
    $taxRate = (float)($store['tax_rate'] ?? 0);

    // Calculate totals
    $subtotal = array_sum(array_column($items, 'subtotal'));
    $discount = (float)($order['discount_amount'] ?? 0);
    $tax = ($subtotal - $discount) * ($taxRate / 100);
    $grandTotal = $subtotal - $discount + $tax;

    // Get table info
    $tableStmt = $pdo->prepare("
        SELECT table_name, seats 
        FROM tables 
        WHERE id = :table_id AND store_id = :store_id
    ");
    $tableStmt->execute([':table_id' => $tableId, ':store_id' => $storeId]);
    $table = $tableStmt->fetch();

    sendResponse([
        'success' => true,
        'store' => [
            'name' => $store['name'],
            'name_th' => $store['name_th'],
            'address' => $store['address'],
            'tel' => $store['tel'],
            'promptpay_id' => $store['promptpay_id']
        ],
        'order_id' => $order['id'],
        'table' => $table,
        'items' => $items,
        'summary' => [
            'subtotal' => round($subtotal, 2),
            'discount' => round($discount, 2),
            'tax_rate' => $taxRate,
            'tax' => round($tax, 2),
            'grand_total' => round($grandTotal, 2),
            'item_count' => count($items)
        ],
        'status' => $order['status'],
        'created_at' => $order['created_at']
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
