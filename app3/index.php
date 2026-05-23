<?php
header('Content-Type: text/html; charset=utf-8');

function conn_parts(string $raw): array {
    $p = [];
    foreach (explode(';', $raw) as $kv) {
        if (strpos($kv, '=') === false) continue;
        [$k, $v] = explode('=', $kv, 2);
        $p[strtolower(trim($k))] = trim($v);
    }
    return $p;
}

echo "<!doctype html><html><head><title>app3</title>";
echo "<style>body{font-family:system-ui,Arial;margin:2rem;color:#1a1a1a}h1{color:#5b2c8f}";
echo "table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:6px 12px}.ok{color:#1a7f37}.bad{color:#b00}</style>";
echo "</head><body><h1>app3 — App Service + Azure SQL</h1>";

try {
    $raw = getenv('SQL_CONNECTION_STRING');
    if (!$raw) throw new RuntimeException('SQL_CONNECTION_STRING not set.');
    $p      = conn_parts($raw);
    $server = explode(',', preg_replace('/^tcp:/', '', $p['server'] ?? ''))[0];
    $dsn    = sprintf('sqlsrv:Server=%s,1433;Database=%s;Encrypt=1;TrustServerCertificate=0', $server, $p['database'] ?? '');

    $pdo  = new PDO($dsn, $p['user id'] ?? '', $p['password'] ?? '', [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $rows = $pdo->query('SELECT TOP 50 Id, SubmittedName, Source, SubmittedAt FROM dbo.SubmittedItems ORDER BY Id DESC')->fetchAll(PDO::FETCH_ASSOC);

    echo "<p class='ok'>&#10003; Connected via Key Vault-referenced credentials (no secret in code).</p>";
    echo "<table><tr><th>Id</th><th>SubmittedName</th><th>Source</th><th>SubmittedAt (UTC)</th></tr>";
    foreach ($rows as $r) {
        echo "<tr><td>{$r['Id']}</td><td>" . htmlspecialchars($r['SubmittedName'])
           . "</td><td>" . htmlspecialchars((string)$r['Source']) . "</td><td>{$r['SubmittedAt']}</td></tr>";
    }
    echo "</table>";
} catch (Throwable $e) {
    http_response_code(500);
    echo "<p class='bad'>Database error: " . htmlspecialchars($e->getMessage()) . "</p>";
}
echo "</body></html>";
