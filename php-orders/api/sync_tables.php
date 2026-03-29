<?php
/**
 * Sync Tables API
 * Receives tables from POS and syncs to database
 */

require_once 'config.php';
validateApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

$input = getJsonInput();
$tables = $input['tables'] ?? [];

if (empty($tables)) {
    sendResponse(['success' => false, 'message' => 'No tables provided']);
}

try {
    $pdo = getConnection();
    $syncedCount = 0;
    $storeId = getStoreId();

    // Prepare statements
    $checkStmt = $pdo->prepare("SELECT id FROM tables WHERE id = :id AND store_id = :store_id");
    $insertStmt = $pdo->prepare("
        INSERT INTO tables (id, store_id, table_name, seats, status, created_at, updated_at)
        VALUES (:id, :store_id, :table_name, :seats, 'available', NOW(), NOW())
    ");
    $updateStmt = $pdo->prepare("
        UPDATE tables SET 
            table_name = :table_name, 
            seats = :seats,
            updated_at = NOW()
        WHERE id = :id AND store_id = :store_id
    ");

    $pdo->beginTransaction();

    foreach ($tables as $table) {
        $id = $table['id'] ?? null;
        if (!$id) continue;

        $tableName = $table['table_name'] ?? "Table $id";
        $seats = $table['seats'] ?? 4;

        // Check if exists
        $checkStmt->execute([':id' => $id, ':store_id' => $storeId]);
        $exists = $checkStmt->fetch();

        if ($exists) {
            // Update
            $updateStmt->execute([
                ':id' => $id,
                ':store_id' => $storeId,
                ':table_name' => $tableName,
                ':seats' => $seats,
            ]);
        } else {
            // Insert
            $insertStmt->execute([
                ':id' => $id,
                ':store_id' => $storeId,
                ':table_name' => $tableName,
                ':seats' => $seats,
            ]);
        }
        $syncedCount++;
    }

    $pdo->commit();

    sendResponse([
        'success' => true,
        'message' => 'Tables synced successfully',
        'synced_count' => $syncedCount,
    ]);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(['success' => false, 'error' => $e->getMessage()], 500);
}
