<?php
/**
 * DELETE /api/delete_items.php
 * Deletes or disables menu items for the authenticated store
 * 
 * Request body (JSON):
 * {"item_ids": [1, 2, 3]}
 * 
 * Or single item:
 * {"item_id": 1}
 * 
 * Query param (alternative):
 * ?item_id=1
 * ?item_ids=1,2,3
 * 
 * Optional:
 * {"soft_delete": true}  // Just mark as unavailable instead of deleting
 */

require_once 'config.php';
$storeId = validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed. Use DELETE or POST'], 405);
}

try {
    $pdo = getConnection();
    $input = getJsonInput();

    // Get item IDs from various sources
    $itemIds = [];
    
    if (!empty($input['item_ids'])) {
        $itemIds = (array)$input['item_ids'];
    } elseif (!empty($input['item_id'])) {
        $itemIds = [(int)$input['item_id']];
    } elseif (!empty($_GET['item_ids'])) {
        $itemIds = array_map('intval', explode(',', $_GET['item_ids']));
    } elseif (!empty($_GET['item_id'])) {
        $itemIds = [(int)$_GET['item_id']];
    }

    if (empty($itemIds)) {
        sendResponse(['error' => 'Missing required field: item_id or item_ids'], 400);
    }

    // Filter to integers only
    $itemIds = array_filter(array_map('intval', $itemIds));
    
    if (empty($itemIds)) {
        sendResponse(['error' => 'No valid item IDs provided'], 400);
    }

    $softDelete = !empty($input['soft_delete']);

    $pdo->beginTransaction();

    $placeholders = implode(',', array_fill(0, count($itemIds), '?'));
    $params = array_merge($itemIds, [$storeId]);

    if ($softDelete) {
        // Soft delete - just mark as unavailable
        $stmt = $pdo->prepare("
            UPDATE menu_items 
            SET is_available = 0, updated_at = NOW() 
            WHERE id IN ($placeholders) AND store_id = ?
        ");
    } else {
        // Hard delete
        $stmt = $pdo->prepare("
            DELETE FROM menu_items 
            WHERE id IN ($placeholders) AND store_id = ?
        ");
    }

    $stmt->execute($params);
    $affected = $stmt->rowCount();

    $pdo->commit();

    sendResponse([
        'success' => true,
        'deleted_count' => $affected,
        'soft_delete' => $softDelete,
        'message' => $softDelete 
            ? "ปิดการแสดง {$affected} รายการ" 
            : "ลบ {$affected} รายการสำเร็จ"
    ]);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
