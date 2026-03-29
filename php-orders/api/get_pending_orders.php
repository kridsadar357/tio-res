<?php
/**
 * GET /api/get_pending_orders.php
 * Returns pending orders from web customers for POS polling (store-specific)
 * 
 * FIXED: Now fetches orders that have pending ITEMS, not based on order's acknowledged flag
 * This ensures new items added to an already-acknowledged order will still be returned.
 * 
 * Query params:
 * - since: Timestamp to get orders after (optional)
 * - limit: Max orders to return (default 50)
 */

require_once 'config.php';
$storeId = validateApiKey();

try {
    $pdo = getConnection();

    $since = $_GET['since'] ?? null;
    $limit = min((int)($_GET['limit'] ?? 50), 100);

    // FIXED: Get orders that have at least one pending item
    // Instead of filtering by order.acknowledged, we check for pending items
    $sql = "
        SELECT DISTINCT
            o.id, o.table_id, o.total_amount, o.status, o.created_at,
            o.guest_count, o.adult_count, o.child_count,
            t.table_name
        FROM orders o
        LEFT JOIN tables t ON o.table_id = t.id
        INNER JOIN order_items oi ON o.id = oi.order_id AND oi.status = 'pending'
        WHERE o.store_id = :store_id
          AND o.status = 'open' 
          AND o.source = 'web'
    ";

    $params = [':store_id' => $storeId];

    if ($since) {
        $sql .= " AND oi.created_at > :since";
        $params[':since'] = $since;
    }

    $sql .= " ORDER BY o.created_at DESC LIMIT $limit";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $orders = $stmt->fetchAll();

    if (empty($orders)) {
        sendResponse([
            'success' => true,
            'orders' => [],
            'count' => 0,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        exit;
    }

    // Get all order IDs
    $orderIds = array_column($orders, 'id');
    $placeholders = implode(',', array_fill(0, count($orderIds), '?'));
    
    // Get all PENDING items for all orders in a single query
    $itemsSql = "
        SELECT 
            oi.order_id,
            oi.id, oi.menu_item_id as item_id, oi.quantity, oi.notes, oi.status,
            oi.price_at_moment as price,
            mi.name, mi.name_th
        FROM order_items oi
        JOIN menu_items mi ON oi.menu_item_id = mi.id
        WHERE oi.order_id IN ($placeholders) AND oi.status = 'pending'
        ORDER BY oi.order_id, oi.id
    ";
    
    $itemsStmt = $pdo->prepare($itemsSql);
    $itemsStmt->execute($orderIds);
    $allItems = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Group items by order_id
    $itemsByOrder = [];
    foreach ($allItems as $item) {
        $orderId = $item['order_id'];
        unset($item['order_id']); // Remove order_id from item data
        if (!isset($itemsByOrder[$orderId])) {
            $itemsByOrder[$orderId] = [];
        }
        $itemsByOrder[$orderId][] = $item;
    }
    
    // Attach items to orders
    foreach ($orders as &$order) {
        $order['items'] = $itemsByOrder[$order['id']] ?? [];
    }

    sendResponse([
        'success' => true,
        'orders' => $orders,
        'count' => count($orders),
        'timestamp' => date('Y-m-d H:i:s')
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}

