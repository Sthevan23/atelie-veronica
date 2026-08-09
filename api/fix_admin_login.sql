-- Reset login + corrige nome do ateliê
-- phpMyAdmin → u586160337_atelie_conf → SQL → Executar

DELETE FROM `admins`;
INSERT INTO `admins` (`email`, `password_hash`) VALUES (
  'admin@veronica.com',
  'veronica123'
);

UPDATE `settings`
SET
  `name` = 'Ateliê Verônica Rodrigues',
  `data_version` = 20
WHERE `id` = 1;
