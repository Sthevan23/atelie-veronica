-- Corrige o nome do ateliê (título da aba / Configurações)
-- Deve bater com o domínio ateliêveronica.com.br → Verônica / Ateliê
-- phpMyAdmin → banco u586160337_atelie_conf → SQL → Executar

UPDATE `settings`
SET
  `name` = 'Ateliê Verônica Rodrigues',
  `data_version` = 19
WHERE `id` = 1;
