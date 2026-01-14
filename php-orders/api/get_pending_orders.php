<?php
/**
 * GET /api/get_pending_orders.php
 * Returns pending orders from web customers for POS polling
 * 
 * Query params:
 * - since: Timestamp to get orders after (optional)
 * - limit: Max orders to return (default 50)
 */

require_once 'config.php';
validateApiKey();

try {
    $pdo = getConnection();

    $since = $_GET['since'] ?? null;
    $limit = min((int)($_GET['limit'] ?? 50), 100);

    $sql = "
        SELECT 
            o.id, o.table_id, o.total_amount, o.status, o.created_at,
            t.table_name
        FROM orders o
        JOIN tables t ON o.table_id = t.id
        WHERE o.status = 'open' 
          AND o.source = 'web'
          AND o.acknowledged = 0
    ";

    $params = [];

    if ($since) {
        $sql .= " AND o.created_at > :since";
        $params[':since'] = $since;
    }

    $sql .= " ORDER BY o.created_at DESC LIMIT $limit";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $orders = $stmt->fetchAll();

    // Get items for each order
    foreach ($orders as &$order) {
        $itemsStmt = $pdo->prepare("
            SELECT 
                oi.id, oi.menu_item_id as item_id, oi.quantity, oi.notes, oi.status,
                mi.name, mi.price
            FROM order_items oi
            JOIN menu_items mi ON oi.menu_item_id = mi.id
            WHERE oi.order_id = :order_id AND oi.status = 'pending'
        ");
        $itemsStmt->execute([':order_id' => $order['id']]);
        $order['items'] = $itemsStmt->fetchAll();
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
