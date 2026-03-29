<?php
/**
 * POST /api/send_orders.php
 * Creates order items for a table (store-specific)
 * PUBLIC ACCESS - Customers can send orders via QR ordering
 * 
 * Request body (JSON):
 * {
 *   "table_id": 1,
 *   "order_id": 123, (optional, creates new if not provided)
 *   "items": [
 *     {"item_id": 1, "quantity": 2, "notes": "No spicy"},
 *     {"item_id": 5, "quantity": 1}
 *   ]
 * }
 */

require_once 'config.php';

// For POST, we need to get table_id from body first
$_tempInput = json_decode(file_get_contents('php://input'), true);
if (!empty($_tempInput['table_id'])) {
    $_GET['table_id'] = $_tempInput['table_id'];
}

$storeId = validatePublicAccess();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

try {
    $pdo = getConnection();
    $input = getJsonInput();

    // Validate required fields
    if (empty($input['table_id']) || empty($input['items'])) {
        sendResponse(['error' => 'Missing required fields: table_id, items'], 400);
    }

    $tableId = (int)$input['table_id'];
    $items = $input['items'];

    // Verify table belongs to this store
    $tableStmt = $pdo->prepare("SELECT id FROM tables WHERE id = ? AND store_id = ?");
    $tableStmt->execute([$tableId, $storeId]);
    if (!$tableStmt->fetch()) {
        sendResponse(['error' => 'Table not found or access denied'], 404);
    }

    $pdo->beginTransaction();

    // Get or create order for this table
    $orderId = $input['order_id'] ?? null;

    if (!$orderId) {
        // Find existing open order for table in this store
        $stmt = $pdo->prepare("SELECT id FROM orders WHERE table_id = ? AND store_id = ? AND status = 'open' LIMIT 1");
        $stmt->execute([$tableId, $storeId]);
        $order = $stmt->fetch();

        if ($order) {
            $orderId = $order['id'];
        } else {
            // Create new order for this store
            $stmt = $pdo->prepare("INSERT INTO orders (store_id, table_id, status, source, created_at) VALUES (?, ?, 'open', 'web', NOW())");
            $stmt->execute([$storeId, $tableId]);
            $orderId = $pdo->lastInsertId();
        }
    }

    // Get menu item prices for this store
    $itemIds = array_column($items, 'item_id');
    
    // Build query with proper placeholders
    if (count($itemIds) > 0) {
        $placeholders = implode(',', array_fill(0, count($itemIds), '?'));
        $menuStmt = $pdo->prepare("SELECT id, price FROM menu_items WHERE store_id = ? AND id IN ($placeholders)");
        $params = array_merge([$storeId], $itemIds);
        $menuStmt->execute($params);
    }
    
    $menuPrices = [];
    if (isset($menuStmt)) {
        while ($row = $menuStmt->fetch()) {
            $menuPrices[$row['id']] = $row['price'];
        }
    }

    // Insert order items with price snapshot
    $insertStmt = $pdo->prepare("INSERT INTO order_items (order_id, menu_item_id, quantity, price_at_moment, notes, status, created_at) VALUES (?, ?, ?, ?, ?, 'pending', NOW())");

    $insertedItems = [];
    foreach ($items as $item) {
        $itemId = (int)$item['item_id'];
        $price = $menuPrices[$itemId] ?? 0;
        $quantity = (int)($item['quantity'] ?? 1);
        $notes = $item['notes'] ?? null;
        
        $insertStmt->execute([$orderId, $itemId, $quantity, $price, $notes]);
        
        $insertedItems[] = [
            'id' => $pdo->lastInsertId(),
            'item_id' => $itemId,
            'quantity' => $quantity,
            'price' => $price
        ];
    }

    // Update order total
    $updateStmt = $pdo->prepare("UPDATE orders SET total_amount = (SELECT COALESCE(SUM(oi.quantity * oi.price_at_moment), 0) FROM order_items oi WHERE oi.order_id = ?), updated_at = NOW() WHERE id = ?");
    $updateStmt->execute([$orderId, $orderId]);

    $pdo->commit();

    sendResponse([
        'success' => true,
        'order_id' => $orderId,
        'items_added' => count($insertedItems),
        'items' => $insertedItems,
        'message' => 'ส่งออเดอร์สำเร็จ'
    ]);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
