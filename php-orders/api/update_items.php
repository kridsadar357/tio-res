<?php
/**
 * PUT /api/update_items.php
 * Updates menu items (for POS sync)
 * 
 * Request body (JSON):
 * {
 *   "items": [
 *     {"id": 1, "name": "Item Name", "price": 100, "is_available": 1},
 *     ...
 *   ]
 * }
 * 
 * Or single item:
 * {"id": 1, "name": "Item Name", "price": 100}
 */

require_once 'config.php';
validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed. Use PUT or POST'], 405);
}

try {
    $pdo = getConnection();
    $input = getJsonInput();

    // Handle both single item and array of items
    $items = isset($input['items']) ? $input['items'] : [$input];

    if (empty($items) || !is_array($items)) {
        sendResponse(['error' => 'Invalid input format'], 400);
    }

    $pdo->beginTransaction();

    $updateStmt = $pdo->prepare("
        UPDATE menu_items SET 
            name = COALESCE(:name, name),
            price = COALESCE(:price, price),
            description = COALESCE(:description, description),
            image_url = COALESCE(:image_url, image_url),
            is_available = COALESCE(:is_available, is_available),
            updated_at = NOW()
        WHERE id = :id
    ");

    $updated = 0;
    foreach ($items as $item) {
        if (empty($item['id'])) continue;

        $updateStmt->execute([
            ':id' => (int)$item['id'],
            ':name' => $item['name'] ?? null,
            ':price' => isset($item['price']) ? (float)$item['price'] : null,
            ':description' => $item['description'] ?? null,
            ':image_url' => $item['image_url'] ?? null,
            ':is_available' => isset($item['is_available']) ? (int)$item['is_available'] : null,
        ]);

        if ($updateStmt->rowCount() > 0) {
            $updated++;
        }
    }

    $pdo->commit();

    sendResponse([
        'success' => true,
        'updated_count' => $updated,
        'message' => "อัพเดท {$updated} รายการสำเร็จ"
    ]);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
