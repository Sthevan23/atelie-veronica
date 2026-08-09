-- Taxa de entrega: R$ 5,00
-- phpMyAdmin → u586160337_atelie_conf → SQL → Executar

UPDATE `settings`
SET
  `delivery_fee` = 5.00,
  `delivery_note` = 'Bairros mais afastados: consultar',
  `data_version` = 16
WHERE `id` = 1;
