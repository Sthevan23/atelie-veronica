-- Atualiza endereço do Ateliê Verônica Rodrigues
-- phpMyAdmin → banco u586160337_atelie_conf → SQL → Executar

UPDATE `settings`
SET
  `address` = 'Rua Padre Francisco Goulart, 610 — Bairro Novo Horizonte 2',
  `data_version` = 18
WHERE `id` = 1;
