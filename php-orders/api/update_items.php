<?php
/**
 * PUT /api/update_items.php
 * Updates or creates menu items for the authenticated store (POS sync)
 * 
 * Request body (JSON):
 * {
 *   "items": [
 *     {"id": 1, "name": "Item Name", "price": 100, "is_available": 1},
 *     {"name": "New Item", "price": 50, "category_id": 1}  // No ID = create new
 *   ]
 * }
 * 
 * Or single item:
 * {"id": 1, "name": "Item Name", "price": 100}
 */

require_once 'config.php';
$storeId = validateApiKey();

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
            name_en = COALESCE(:name_en, name_en),
            name_th = COALESCE(:name_th, name_th),
            name_cn = COALESCE(:name_cn, name_cn),
            price = COALESCE(:price, price),
            description = COALESCE(:description, description),
            image_url = COALESCE(:image_url, image_url),
            category_id = COALESCE(:category_id, category_id),
            is_available = COALESCE(:is_available, is_available),
            is_extra_charge = COALESCE(:is_extra_charge, is_extra_charge),
            updated_at = NOW()
        WHERE id = :id AND store_id = :store_id
    ");

    $insertStmt = $pdo->prepare("
        INSERT INTO menu_items 
            (store_id, name, name_en, name_th, name_cn, price, description, image_url, category_id, is_available, is_extra_charge, created_at)
        VALUES 
            (:store_id, :name, :name_en, :name_th, :name_cn, :price, :description, :image_url, :category_id, :is_available, :is_extra_charge, NOW())
    ");

    $updated = 0;
    $created = 0;
    $results = [];

    foreach ($items as $item) {
        if (!empty($item['id'])) {
            // Update existing item
            $updateStmt->execute([
                ':id' => (int)$item['id'],
                ':store_id' => $storeId,
                ':name' => $item['name'] ?? null,
                ':name_en' => $item['name_en'] ?? null,
                ':name_th' => $item['name_th'] ?? null,
                ':name_cn' => $item['name_cn'] ?? null,
                ':price' => isset($item['price']) ? (float)$item['price'] : null,
                ':description' => $item['description'] ?? null,
                ':image_url' => $item['image_url'] ?? null,
                ':category_id' => isset($item['category_id']) ? (int)$item['category_id'] : null,
                ':is_available' => isset($item['is_available']) ? (int)$item['is_available'] : null,
                ':is_extra_charge' => isset($item['is_extra_charge']) ? (int)$item['is_extra_charge'] : null,
            ]);

            if ($updateStmt->rowCount() > 0) {
                $updated++;
                $results[] = ['id' => $item['id'], 'action' => 'updated'];
            }
        } else if (!empty($item['name'])) {
            // Create new item
            $insertStmt->execute([
                ':store_id' => $storeId,
                ':name' => $item['name'],
                ':name_en' => $item['name_en'] ?? null,
                ':name_th' => $item['name_th'] ?? null,
                ':name_cn' => $item['name_cn'] ?? null,
                ':price' => (float)($item['price'] ?? 0),
                ':description' => $item['description'] ?? null,
                ':image_url' => $item['image_url'] ?? null,
                ':category_id' => isset($item['category_id']) ? (int)$item['category_id'] : null,
                ':is_available' => (int)($item['is_available'] ?? 1),
                ':is_extra_charge' => (int)($item['is_extra_charge'] ?? 0),
            ]);

            $newId = $pdo->lastInsertId();
            $created++;
            $results[] = ['id' => $newId, 'action' => 'created'];
        }
    }

    $pdo->commit();

    sendResponse([
        'success' => true,
        'updated_count' => $updated,
        'created_count' => $created,
        'results' => $results,
        'message' => "อัพเดท {$updated} รายการ, สร้างใหม่ {$created} รายการ"
    ]);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
