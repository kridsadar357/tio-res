<?php
/**
 * GET /api/get_items.php
 * Returns menu items filtered by buffet_tier_id or category
 * 
 * Query params:
 * - tier_id: Buffet tier ID (optional)
 * - category_id: Category ID (optional)
 * - table_id: Table ID (for context)
 */

require_once 'config.php';
validateApiKey();

try {
    $pdo = getConnection();

    // Build query with optional filters
    $sql = "SELECT 
                i.id, i.name, i.price, i.image_url, i.description,
                c.id as category_id, c.name as category_name
            FROM menu_items i
            LEFT JOIN categories c ON i.category_id = c.id
            WHERE i.is_available = 1";

    $params = [];

    // Filter by buffet tier
    if (!empty($_GET['tier_id'])) {
        $sql .= " AND (i.buffet_tier_id = :tier_id OR i.buffet_tier_id IS NULL)";
        $params[':tier_id'] = (int)$_GET['tier_id'];
    }

    // Filter by category
    if (!empty($_GET['category_id'])) {
        $sql .= " AND i.category_id = :category_id";
        $params[':category_id'] = (int)$_GET['category_id'];
    }

    $sql .= " ORDER BY c.sort_order, i.name";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $items = $stmt->fetchAll();

    // Get categories for filter
    $catStmt = $pdo->query("SELECT id, name FROM categories ORDER BY sort_order");
    $categories = $catStmt->fetchAll();

    sendResponse([
        'success' => true,
        'items' => $items,
        'categories' => $categories,
        'count' => count($items)
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
