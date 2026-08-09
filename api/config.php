<?php
/**
 * Carrega config MySQL. Preferência: config.local.php (não versionado).
 */
$local = __DIR__ . '/config.local.php';
$example = __DIR__ . '/config.local.example.php';

if (is_file($local)) {
  return require $local;
}

if (is_file($example)) {
  return require $example;
}

return [
  'host' => getenv('VERONICA_DB_HOST') ?: 'localhost',
  'port' => (int) (getenv('VERONICA_DB_PORT') ?: 3306),
  'name' => getenv('VERONICA_DB_NAME') ?: 'u586160337_atelie_conf',
  'user' => getenv('VERONICA_DB_USER') ?: 'u586160337_atelie_conf',
  'pass' => getenv('VERONICA_DB_PASS') ?: '',
  'charset' => 'utf8mb4',
];
