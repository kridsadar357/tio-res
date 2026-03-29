<?php
/**
 * Sync Buffet Tiers API
 * Receives buffet tiers from POS and syncs to database
 */

require_once 'config.php';
validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

$input = getJsonInput();
$tiers = $input['buffet_tiers'] ?? [];

if (empty($tiers)) {
    sendResponse(['success' => false, 'message' => 'No buffet tiers provided']);
}

try {
    $pdo = getConnection();
    $syncedCount = 0;
    $storeId = getStoreId();

    // Prepare statements - using 'price' column (matches hosting schema)
    $checkStmt = $pdo->prepare("SELECT id FROM buffet_tiers WHERE id = :id AND store_id = :store_id");
        $insertStmt = $pdo->prepare("
        INSERT INTO buffet_tiers (id, store_id, name, name_th, price, description, is_active, sort_order, excluded_category_ids, created_at, updated_at)
        VALUES (:id, :store_id, :name, :name_th, :price, :description, :is_active, :sort_order, :excluded_category_ids, NOW(), NOW())
    ");
    $updateStmt = $pdo->prepare("
        UPDATE buffet_tiers SET 
            name = :name, 
            name_th = :name_th, 
            price = :price,
            description = :description,
            is_active = :is_active,
            sort_order = :sort_order,
            excluded_category_ids = :excluded_category_ids,
            updated_at = NOW()
        WHERE id = :id AND store_id = :store_id
    ");

    $pdo->beginTransaction();

    foreach ($tiers as $tier) {
        $id = $tier['id'] ?? null;
        if (!$id) continue;

        $name = $tier['name'] ?? 'Unnamed';
        $nameTh = $tier['name_th'] ?? $name;
        $price = $tier['price'] ?? 0;
        $description = $tier['description'] ?? '';
        $isActive = $tier['is_active'] ?? 1;
        $sortOrder = $tier['sort_order'] ?? 0;
        $excludedIds = $tier['excluded_category_ids'] ?? null;

        // Check if exists
        $checkStmt->execute([':id' => $id, ':store_id' => $storeId]);
        $exists = $checkStmt->fetch();

        if ($exists) {
            // Update
            $updateStmt->execute([
                ':id' => $id,
                ':store_id' => $storeId,
                ':name' => $name,
                ':name_th' => $nameTh,
                ':price' => $price,
                ':description' => $description,
                ':is_active' => $isActive,
                ':sort_order' => $sortOrder,
                ':excluded_category_ids' => $excludedIds,
            ]);
        } else {
            // Insert
            $insertStmt->execute([
                ':id' => $id,
                ':store_id' => $storeId,
                ':name' => $name,
                ':name_th' => $nameTh,
                ':price' => $price,
                ':description' => $description,
                ':is_active' => $isActive,
                ':sort_order' => $sortOrder,
                ':excluded_category_ids' => $excludedIds,
            ]);
        }
        $syncedCount++;
    }

    $pdo->commit();

    sendResponse([
        'success' => true,
        'message' => 'Buffet tiers synced successfully',
        'synced_count' => $syncedCount,
    ]);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['success' => false, 'error' => $e->getMessage()], 500);
}
