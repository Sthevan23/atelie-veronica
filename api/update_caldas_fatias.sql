-- Caldas nas fatias (escolha única)
-- phpMyAdmin → u586160337_atelie_conf → SQL → Executar

DELETE FROM `product_flavors`
WHERE `product_id` IN (
  'p-fatia-chocobrownie',
  'p-fatia-brigadeiro-maracuja',
  'p-fatia-palha',
  'p-fatia-oreo',
  'p-fatia-matilda',
  'p-fatia-ouro-branco'
);

INSERT INTO `product_flavors` (`product_id`, `flavor`, `sort_order`) VALUES
('p-fatia-chocobrownie', 'Calda caramelo', 0),
('p-fatia-chocobrownie', 'Calda de chocolate', 1),
('p-fatia-chocobrownie', 'Calda de ninho', 2),
('p-fatia-brigadeiro-maracuja', 'Calda caramelo', 0),
('p-fatia-brigadeiro-maracuja', 'Calda de chocolate', 1),
('p-fatia-brigadeiro-maracuja', 'Calda de ninho', 2),
('p-fatia-palha', 'Calda caramelo', 0),
('p-fatia-palha', 'Calda de chocolate', 1),
('p-fatia-palha', 'Calda de ninho', 2),
('p-fatia-oreo', 'Calda caramelo', 0),
('p-fatia-oreo', 'Calda de chocolate', 1),
('p-fatia-oreo', 'Calda de ninho', 2),
('p-fatia-matilda', 'Calda caramelo', 0),
('p-fatia-matilda', 'Calda de chocolate', 1),
('p-fatia-matilda', 'Calda de ninho', 2),
('p-fatia-ouro-branco', 'Calda caramelo', 0),
('p-fatia-ouro-branco', 'Calda de chocolate', 1),
('p-fatia-ouro-branco', 'Calda de ninho', 2);

UPDATE `settings` SET `data_version` = 17 WHERE `id` = 1;
