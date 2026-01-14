<?php
/**
 * POST /api/send_orders.php
 * Creates order items for a table
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
validateApiKey();

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

    $pdo->beginTransaction();

    // Get or create order for this table
    $orderId = $input['order_id'] ?? null;

    if (!$orderId) {
        // Find existing open order for table
        $stmt = $pdo->prepare("SELECT id FROM orders WHERE table_id = :table_id AND status = 'open' LIMIT 1");
        $stmt->execute([':table_id' => $tableId]);
        $order = $stmt->fetch();

        if ($order) {
            $orderId = $order['id'];
        } else {
            // Create new order
            $stmt = $pdo->prepare("INSERT INTO orders (table_id, status, created_at) VALUES (:table_id, 'open', NOW())");
            $stmt->execute([':table_id' => $tableId]);
            $orderId = $pdo->lastInsertId();
        }
    }

    // Insert order items
    $insertStmt = $pdo->prepare("
        INSERT INTO order_items (order_id, menu_item_id, quantity, notes, status, created_at)
        VALUES (:order_id, :item_id, :quantity, :notes, 'pending', NOW())
    ");

    $insertedItems = [];
    foreach ($items as $item) {
        $insertStmt->execute([
            ':order_id' => $orderId,
            ':item_id' => (int)$item['item_id'],
            ':quantity' => (int)($item['quantity'] ?? 1),
            ':notes' => $item['notes'] ?? null
        ]);
        $insertedItems[] = [
            'id' => $pdo->lastInsertId(),
            'item_id' => $item['item_id'],
            'quantity' => $item['quantity'] ?? 1
        ];
    }

    // Update order total
    $stmt = $pdo->prepare("
        UPDATE orders SET 
            total_amount = (
                SELECT COALESCE(SUM(oi.quantity * mi.price), 0)
                FROM order_items oi
                JOIN menu_items mi ON oi.menu_item_id = mi.id
                WHERE oi.order_id = :order_id
            ),
            updated_at = NOW()
        WHERE id = :order_id
    ");
    $stmt->execute([':order_id' => $orderId]);

    $pdo->commit();

    sendResponse([
        'success' => true,
        'order_id' => $orderId,
        'items_added' => count($insertedItems),
        'items' => $insertedItems,
        'message' => 'ส่งออเดอร์สำเร็จ'
    ]);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
