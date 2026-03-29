<?php
/**
 * Sync Categories API
 * Receives categories from POS and syncs to database
 * Supports multi-language: name (TH default), name_en, name_cn
 */

require_once 'config.php';
validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

$input = getJsonInput();
$categories = $input['categories'] ?? [];

if (empty($categories)) {
    sendResponse(['success' => false, 'message' => 'No categories provided']);
}

try {
    $pdo = getConnection();
    $syncedCount = 0;
    $storeId = getStoreId();

    // Prepare statements with multi-language support
    $checkStmt = $pdo->prepare("SELECT id FROM categories WHERE id = :id AND store_id = :store_id");
    $insertStmt = $pdo->prepare("
        INSERT INTO categories (id, store_id, name, name_en, name_th, name_cn, sort_order, is_active, created_at, updated_at)
        VALUES (:id, :store_id, :name, :name_en, :name_th, :name_cn, :sort_order, :is_active, NOW(), NOW())
    ");
    $updateStmt = $pdo->prepare("
        UPDATE categories SET 
            name = :name, 
            name_en = :name_en,
            name_th = :name_th, 
            name_cn = :name_cn,
            sort_order = :sort_order, 
            is_active = :is_active,
            updated_at = NOW()
        WHERE id = :id AND store_id = :store_id
    ");

    $pdo->beginTransaction();

    foreach ($categories as $cat) {
        $id = $cat['id'] ?? null;
        if (!$id) continue;

        // Support both name and name_th for Thai name
        $name = $cat['name'] ?? 'Unnamed';
        $nameEn = $cat['name_en'] ?? null;
        $nameTh = $cat['name_th'] ?? $name;
        $nameCn = $cat['name_cn'] ?? null;
        $sortOrder = $cat['sort_order'] ?? 0;
        $isActive = $cat['is_active'] ?? 1;

        // Check if exists
        $checkStmt->execute([':id' => $id, ':store_id' => $storeId]);
        $exists = $checkStmt->fetch();

        if ($exists) {
            // Update
            $updateStmt->execute([
                ':id' => $id,
                ':store_id' => $storeId,
                ':name' => $name,
                ':name_en' => $nameEn,
                ':name_th' => $nameTh,
                ':name_cn' => $nameCn,
                ':sort_order' => $sortOrder,
                ':is_active' => $isActive,
            ]);
        } else {
            // Insert
            $insertStmt->execute([
                ':id' => $id,
                ':store_id' => $storeId,
                ':name' => $name,
                ':name_en' => $nameEn,
                ':name_th' => $nameTh,
                ':name_cn' => $nameCn,
                ':sort_order' => $sortOrder,
                ':is_active' => $isActive,
            ]);
        }
        $syncedCount++;
    }

    $pdo->commit();

    sendResponse([
        'success' => true,
        'message' => 'Categories synced successfully',
        'synced_count' => $syncedCount,
    ]);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['success' => false, 'error' => $e->getMessage()], 500);
}
