<?php
/**
 * Sync Menu Items API
 * Receives menu items from POS and syncs to database
 */

require_once 'config.php';
validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

$input = getJsonInput();
$items = $input['items'] ?? [];

if (empty($items)) {
    sendResponse(['success' => false, 'message' => 'No menu items provided']);
}

try {
    $pdo = getConnection();
    $syncedCount = 0;
    $storeId = getStoreId();

    // Prepare statements
    $checkStmt = $pdo->prepare("SELECT id FROM menu_items WHERE id = :id AND store_id = :store_id");
    $insertStmt = $pdo->prepare("
        INSERT INTO menu_items (id, store_id, category_id, name, name_en, name_th, name_cn, description, price, image_url, is_available, buffet_tier_id, created_at, updated_at)
        VALUES (:id, :store_id, :category_id, :name, :name_en, :name_th, :name_cn, :description, :price, :image_url, :is_available, :buffet_tier_id, NOW(), NOW())
    ");
    $updateStmt = $pdo->prepare("
        UPDATE menu_items SET 
            category_id = :category_id,
            name = :name, 
            name_en = :name_en,
            name_th = :name_th, 
            name_cn = :name_cn,
            description = :description,
            price = :price,
            image_url = :image_url,
            is_available = :is_available,
            buffet_tier_id = :buffet_tier_id,
            updated_at = NOW()
        WHERE id = :id AND store_id = :store_id
    ");

    $pdo->beginTransaction();

    foreach ($items as $item) {
        $id = $item['id'] ?? null;
        if (!$id) continue;

        $categoryId = $item['category_id'] ?? null;
        $name = $item['name'] ?? 'Unnamed';
        $nameEn = $item['name_en'] ?? null;
        $nameTh = $item['name_th'] ?? $name;
        $nameCn = $item['name_cn'] ?? null;
        $description = $item['description'] ?? null;
        $price = $item['price'] ?? 0;
        $imageUrl = $item['image_url'] ?? null;
        $isAvailable = $item['is_available'] ?? 1;
        $buffetTierId = $item['buffet_tier_id'] ?? null;

        // Check if exists
        $checkStmt->execute([':id' => $id, ':store_id' => $storeId]);
        $exists = $checkStmt->fetch();

        $params = [
            ':id' => $id,
            ':store_id' => $storeId,
            ':category_id' => $categoryId,
            ':name' => $name,
            ':name_en' => $nameEn,
            ':name_th' => $nameTh,
            ':name_cn' => $nameCn,
            ':description' => $description,
            ':price' => $price,
            ':image_url' => $imageUrl,
            ':is_available' => $isAvailable,
            ':buffet_tier_id' => $buffetTierId,
        ];

        if ($exists) {
            // Update
            $updateStmt->execute($params);
        } else {
            // Insert
            $insertStmt->execute($params);
        }
        $syncedCount++;
    }

    $pdo->commit();

    sendResponse([
        'success' => true,
        'message' => 'Menu items synced successfully',
        'synced_count' => $syncedCount,
    ]);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['success' => false, 'error' => $e->getMessage()], 500);
}
