<?php
/**
 * GET /api/get_items.php
 * Returns menu items for the store
 * PUBLIC ACCESS - Uses table_id or API key for store context
 * 
 * Query params:
 * - table_id: Table ID (required for public access)
 * - tier_id: Buffet tier ID (optional, filter items by tier)
 * - category_id: Category ID (optional, filter items by category)
 * - api_key: API key (alternative to table_id for admin access)
 */

require_once 'config.php';
$storeId = validatePublicAccess();

try {
    $pdo = getConnection();

    // Build query with store filter
    $sql = "SELECT 
                i.id, i.name, i.name_en, i.name_th, i.name_cn, i.price, i.image_url, i.description,
                i.is_extra_charge,
                c.id as category_id, c.name as category_name, c.name_en as category_name_en, c.name_th as category_name_th, c.name_cn as category_name_cn
            FROM menu_items i
            LEFT JOIN categories c ON i.category_id = c.id
            WHERE i.store_id = :store_id AND i.is_available = 1";

    $params = [':store_id' => $storeId];
    $excludedCategoryIds = [];

    // Filter by buffet tier
    if (!empty($_GET['tier_id'])) {
        $tierId = (int)$_GET['tier_id'];
        $sql .= " AND (i.buffet_tier_id = :tier_id OR i.buffet_tier_id IS NULL)";
        $params[':tier_id'] = $tierId;
        
        // Get excluded categories for this tier
        $tierStmt = $pdo->prepare("SELECT excluded_category_ids FROM buffet_tiers WHERE id = :id");
        $tierStmt->execute([':id' => $tierId]);
        $tier = $tierStmt->fetch();
        
        if ($tier && !empty($tier['excluded_category_ids'])) {
            $excludedRaw = $tier['excluded_category_ids'];
            // Handle JSON or comma-separated
            $decoded = json_decode($excludedRaw, true);
            if (is_array($decoded)) {
                $excludedCategoryIds = $decoded;
            } else {
                $excludedCategoryIds = array_map('intval', explode(',', $excludedRaw));
            }
        }
    }

    // Filter by category
    if (!empty($_GET['category_id'])) {
        $sql .= " AND i.category_id = :category_id";
        $params[':category_id'] = (int)$_GET['category_id'];
    }
    

    
    // NOTE: PDO doesn't support mixing named (:name) and positional (?) params easily.
    // Let's use named params for excluded categories dynamically.
    if (!empty($excludedCategoryIds)) {
        $excParams = [];
        foreach ($excludedCategoryIds as $k => $id) {
            $pName = ":exc_cat_$k";
            $excParams[] = $pName;
            $params[$pName] = $id;
        }
        $inQuery = implode(',', $excParams);

        $sql .= " AND (i.category_id NOT IN ($inQuery) OR i.category_id IS NULL)";
    }

    $sql .= " ORDER BY c.sort_order, i.sort_order, i.name";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $items = $stmt->fetchAll();

    // Get categories for this store
    $catSql = "SELECT id, name, name_en, name_th, name_cn 
               FROM categories 
               WHERE store_id = :store_id AND is_active = 1";
               
    if (!empty($excludedCategoryIds)) {
        $catSql .= " AND id NOT IN (" . implode(',', $excParams) . ")";
        // $params already has store_id and exc_cat_x
    }
    $catSql .= " ORDER BY sort_order";
    
    $catStmt = $pdo->prepare($catSql);
    // Filter params for category query (only store_id and exclusions)
    $catParams = [':store_id' => $storeId];
    if (!empty($excludedCategoryIds)) {
        foreach ($excludedCategoryIds as $k => $id) {
             $catParams[":exc_cat_$k"] = $id;
        }
    }
    
    $catStmt->execute($catParams);
    $categories = $catStmt->fetchAll();

    // Include store info in response
    $store = getStoreInfo();

    sendResponse([
        'success' => true,
        'store' => [
            'name' => $store['name'],
            'name_th' => $store['name_th'],
            'logo_url' => $store['logo_url']
        ],
        'items' => $items,
        'categories' => $categories,
        'count' => count($items)
    ]);

} catch (PDOException $e) {
    sendResponse(['error' => 'Database error', 'message' => $e->getMessage()], 500);
}
