<?php
header('Content-Type: text/html; charset=utf-8');

$conn = getenv('SQL_CONNECTION_STRING') ?: '';
$resolved = $conn !== '' && strpos($conn, '@Microsoft.KeyVault') === false;
$server = '';
if (preg_match('/Server=tcp:([^,;]+)/i', $conn, $m)) {
    $server = $m[1];
}

echo "<!doctype html><html><head><title>app2</title>";
echo "<style>body{font-family:system-ui,Arial;margin:2rem;color:#1a1a1a}h1{color:#5b2c8f}.ok{color:#1a7f37}.bad{color:#b00}</style>";
echo "</head><body><h1>app2 — running on Azure App Service</h1>";
echo "<p>PHP " . PHP_VERSION . " on " . htmlspecialchars(php_uname('s')) . "</p>";
if ($resolved) {
    echo "<p class='ok'>&#10003; SQL connection string resolved from Key Vault via managed identity.</p>";
    echo "<p>Target server: <code>" . htmlspecialchars($server) . "</code> (password never exposed to the app code).</p>";
} else {
    echo "<p class='bad'>Key Vault reference did not resolve — check the managed identity's 'Key Vault Secrets User' role.</p>";
}
echo "</body></html>";
