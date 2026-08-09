-- Atualiza WhatsApp e Instagram no banco da Verônica
-- phpMyAdmin → banco u586160337_atelie_conf → SQL → Executar

UPDATE `settings`
SET
  `whatsapp` = '5537998741557',
  `instagram` = 'https://www.instagram.com/veronicabolospiumhi',
  `instagram_user` = '@veronicabolospiumhi',
  `data_version` = 8
WHERE `id` = 1;
