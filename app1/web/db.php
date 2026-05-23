<?php
/**
 * db.php — single place that turns a connection string into a PDO handle.
 *
 * SECURITY: the connection string is read from the SQL_CONNECTION_STRING
 * environment variable. It is NEVER written into source.
 *   - On AKS  : the Key Vault CSI driver mounts the secret and an init step
 *               exports it into the environment (see deployment.yaml).
 *   - On App Service / Functions : the value is a Key Vault *reference* app
 *               setting, resolved by the platform via managed identity.
 */

function db_connect(): PDO
{
    $raw = getenv('SQL_CONNECTION_STRING');
    if ($raw === false || $raw === '') {
        throw new RuntimeException('SQL_CONNECTION_STRING is not set.');
    }

    // Parse the standard ADO-style connection string into PDO parts.
    $parts = [];
    foreach (explode(';', $raw) as $kv) {
        if (strpos($kv, '=') === false) {
            continue;
        }
        [$k, $v] = explode('=', $kv, 2);
        $parts[strtolower(trim($k))] = trim($v);
    }

    $server = preg_replace('/^tcp:/', '', $parts['server'] ?? '');
    $server = explode(',', $server)[0]; // drop the ,1433 port suffix
    $dbName = $parts['database'] ?? '';
    $user   = $parts['user id'] ?? ($parts['uid'] ?? '');
    $pass   = $parts['password'] ?? '';

    $dsn = sprintf('sqlsrv:Server=%s,1433;Database=%s;Encrypt=1;TrustServerCertificate=0', $server, $dbName);

    return new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
}
