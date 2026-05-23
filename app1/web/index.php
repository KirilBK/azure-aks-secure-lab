<?php
require __DIR__ . '/db.php';

header('Content-Type: text/html; charset=utf-8');
echo "<!doctype html><html><head><title>app1 · AKS</title>";
echo "<style>body{font-family:system-ui,Arial;margin:2rem;color:#1a1a1a}";
echo "table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:6px 12px}";
echo "h1{color:#5b2c8f}.ok{color:#1a7f37}</style></head><body>";
echo "<h1>app1 — running on Azure Kubernetes Service</h1>";

try {
    $pdo  = db_connect();
    $rows = $pdo->query('SELECT TOP 50 Id, SubmittedName, Source, SubmittedAt FROM dbo.SubmittedItems ORDER BY Id DESC')->fetchAll();

    echo "<p class='ok'>&#10003; Connected to Azure SQL via the Key&nbsp;Vault-mounted secret. No credentials in this image.</p>";
    echo "<table><tr><th>Id</th><th>SubmittedName</th><th>Source</th><th>SubmittedAt (UTC)</th></tr>";
    foreach ($rows as $r) {
        echo "<tr><td>" . htmlspecialchars($r['Id']) . "</td><td>" . htmlspecialchars($r['SubmittedName'])
           . "</td><td>" . htmlspecialchars((string) $r['Source']) . "</td><td>" . htmlspecialchars($r['SubmittedAt']) . "</td></tr>";
    }
    echo "</table>";
} catch (Throwable $e) {
    http_response_code(500);
    echo "<p style='color:#b00'>Database error: " . htmlspecialchars($e->getMessage()) . "</p>";
}

echo "</body></html>";
