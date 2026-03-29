<?php
/**
 * Sync Store Info API
 * Updates store information from POS settings
 */

require_once 'config.php';
$storeId = validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

$input = getJsonInput();

try {
    $pdo = getConnection();
    
    // Build dynamic update query based on provided fields
    $updates = [];
    $params = [':id' => $storeId];
    
    $allowedFields = [
        'name' => 'name',
        'name_th' => 'name_th',
        'address' => 'address',
        'tel' => 'tel',
        'email' => 'email',
        'logo_url' => 'logo_url',
        'currency' => 'currency',
        'tax_rate' => 'tax_rate',
        'promptpay_id' => 'promptpay_id',
    ];
    
    foreach ($allowedFields as $inputKey => $dbColumn) {
        if (isset($input[$inputKey])) {
            $updates[] = "$dbColumn = :$inputKey";
            $params[":$inputKey"] = $input[$inputKey];
        }
    }
    
    if (empty($updates)) {
        sendResponse(['success' => false, 'message' => 'No fields to update']);
    }
    
    $sql = "UPDATE stores SET " . implode(', ', $updates) . " WHERE id = :id";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    
    // Fetch updated store info
    $stmt = $pdo->prepare("SELECT * FROM stores WHERE id = :id");
    $stmt->execute([':id' => $storeId]);
    $store = $stmt->fetch();
    
    sendResponse([
        'success' => true,
        'message' => 'Store info updated successfully',
        'store' => [
            'id' => $store['id'],
            'name' => $store['name'],
            'name_th' => $store['name_th'],
            'address' => $store['address'],
            'tel' => $store['tel'],
            'logo_url' => $store['logo_url'],
        ]
    ]);

} catch (PDOException $e) {
    sendResponse(['success' => false, 'error' => $e->getMessage()], 500);
}
