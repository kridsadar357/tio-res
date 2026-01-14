<?php
/**
 * DELETE /api/delete_items.php
 * Deletes menu items (for POS sync when items are removed)
 * 
 * Query params:
 * - id: Single item ID
 * - ids: Comma-separated item IDs (e.g., "1,2,3")
 * 
 * Or Request body (JSON):
 * {"ids": [1, 2, 3]}
 */

require_once 'config.php';
validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed. Use DELETE or POST'], 405);
}

try {
    $pdo = getConnection();

    // Get IDs from various sources
    $ids = [];

    // From query string
    if (!empty($_GET['id'])) {
        $ids[] = (int)$_GET['id'];
    }
    if (!empty($_GET['ids'])) {
        $ids = array_merge($ids, array_map('intval', explode(',', $_GET['ids'])));
    }

    // From request body
    $input = getJsonInput();
    if (!empty($input['ids']) && is_array($input['ids'])) {
        $ids = array_merge($ids, array_map('intval', $input['ids']));
    }
    if (!empty($input['id'])) {
        $ids[] = (int)$input['id'];
    }

    // Remove duplicates and validate
    $ids = array_unique(array_filter($ids));

    if (empty($ids)) {
        sendResponse(['error' => 'No item IDs provided'], 400);
    }

    // Soft delete (mark as unavailable) instead of hard delete
    // This preserves order history integrity
    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    
    // Option 1: Soft delete
    $stmt = $pdo->prepare("UPDATE menu_items SET is_available = 0, updated_at = NOW() WHERE id IN ($placeholders)");
    
    // Option 2: Hard delete (uncomment if preferred)
    // $stmt = $pdo->prepare("DELETE FROM menu_items WHERE id IN ($placeholders)");

    $stmt->execute($ids);
    $deletedCount = $stmt->rowCount();

    sendResponse([
        'success' => true,
        'deleted_count' => $deletedCount,
        'ids' => $ids,
        'message' => "ลบ {$deletedCount} รายการสำเร็จ"
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
