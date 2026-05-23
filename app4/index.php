<?php
// app4 — minimal stateless service deployed as an Azure Container Instance.
// No database; it just proves the ACR-built image runs in ACI (exam T211/T212).
header('Content-Type: text/html; charset=utf-8');
echo "<!doctype html><html><head><title>app4 · ACI</title>";
echo "<style>body{font-family:system-ui,Arial;margin:2rem;color:#1a1a1a}h1{color:#5b2c8f}</style></head><body>";
echo "<h1>app4 — running on Azure Container Instances</h1>";
echo "<p>Hostname: " . htmlspecialchars(gethostname()) . "</p>";
echo "<p>Time (UTC): " . gmdate('Y-m-d H:i:s') . "</p>";
echo "<p>Image pulled from Azure Container Registry; container started by ACI.</p>";
echo "</body></html>";
