-- =========================================================
-- Ateliê Verônica Rodrigues — schema MySQL (Hostinger / phpMyAdmin)
-- Domínio: ateliêveronica.com.br
-- Charset: utf8mb4
--
-- COMO USAR NA HOSTINGER:
-- 1) hPanel → Bancos de Dados MySQL → criar banco (ex.: uXXXX_veronica)
-- 2) Criar usuário e associar ao banco (todas as permissões)
-- 3) phpMyAdmin → selecionar o banco → aba SQL
-- 4) Cole este arquivo inteiro e clique em Executar
-- 5) Atualize api/config.local.php com name / user / pass do banco novo
--
-- NÃO rode CREATE DATABASE — a Hostinger já cria o banco no hPanel.
-- ATENÇÃO: este script APAGA as tabelas listadas e recria do zero.
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `finance`;
DROP TABLE IF EXISTS `coupons`;
DROP TABLE IF EXISTS `clients`;
DROP TABLE IF EXISTS `product_flavor_prices`;
DROP TABLE IF EXISTS `product_flavors`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `gallery`;
DROP TABLE IF EXISTS `faq`;
DROP TABLE IF EXISTS `reviews`;
DROP TABLE IF EXISTS `settings`;
DROP TABLE IF EXISTS `admins`;

CREATE TABLE `admins` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(190) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admins_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `settings` (
  `id` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `name` VARCHAR(190) NOT NULL,
  `tagline` VARCHAR(255) DEFAULT NULL,
  `logo` VARCHAR(500) DEFAULT NULL,
  `banner` VARCHAR(500) DEFAULT NULL,
  `sobre_image` VARCHAR(500) DEFAULT NULL,
  `whatsapp` VARCHAR(30) DEFAULT NULL,
  `instagram` VARCHAR(255) DEFAULT NULL,
  `instagram_user` VARCHAR(120) DEFAULT NULL,
  `facebook` VARCHAR(255) DEFAULT NULL,
  `email` VARCHAR(190) DEFAULT NULL,
  `address` VARCHAR(500) DEFAULT NULL,
  `hours` VARCHAR(255) DEFAULT NULL,
  `followers` VARCHAR(50) DEFAULT NULL,
  `posts` VARCHAR(50) DEFAULT NULL,
  `map_embed` TEXT,
  `hero_badge` VARCHAR(255) DEFAULT NULL,
  `hero_story` JSON DEFAULT NULL,
  `sobre_text1` TEXT,
  `sobre_text2` TEXT,
  `delivery_fee` DECIMAL(10,2) NOT NULL DEFAULT 5.00,
  `delivery_note` VARCHAR(255) DEFAULT 'Bairros mais afastados: consultar',
  `data_version` INT UNSIGNED NOT NULL DEFAULT 7,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `categories` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `slug` VARCHAR(120) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_categories_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `products` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(190) NOT NULL,
  `description` TEXT,
  `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `price_from` TINYINT(1) NOT NULL DEFAULT 0,
  `category_id` VARCHAR(64) NOT NULL,
  `image` MEDIUMTEXT DEFAULT NULL,
  `featured` TINYINT(1) NOT NULL DEFAULT 0,
  `slug` VARCHAR(190) NOT NULL,
  `size` VARCHAR(50) DEFAULT NULL,
  `promo_active` TINYINT(1) NOT NULL DEFAULT 0,
  `promo_price` DECIMAL(10,2) DEFAULT NULL,
  `promo_label` VARCHAR(120) DEFAULT NULL,
  `best_seller` TINYINT(1) NOT NULL DEFAULT 0,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_products_slug` (`slug`),
  KEY `idx_products_category` (`category_id`),
  CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_flavors` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` VARCHAR(64) NOT NULL,
  `flavor` VARCHAR(190) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_pf_product` (`product_id`),
  CONSTRAINT `fk_pf_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_flavor_prices` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` VARCHAR(64) NOT NULL,
  `flavor` VARCHAR(190) NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pfp` (`product_id`, `flavor`),
  CONSTRAINT `fk_pfp_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `gallery` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `image` VARCHAR(500) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `clients` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(190) NOT NULL,
  `email` VARCHAR(190) DEFAULT NULL,
  `phone` VARCHAR(30) DEFAULT NULL,
  `address` VARCHAR(500) DEFAULT NULL,
  `loyalty_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Pedidos fora do site (ajuste fidelidade)',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_clients_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orders` (
  `id` VARCHAR(64) NOT NULL,
  `number` VARCHAR(40) NOT NULL,
  `client_id` VARCHAR(64) DEFAULT NULL,
  `client_name` VARCHAR(190) NOT NULL,
  `client_whatsapp` VARCHAR(30) DEFAULT NULL,
  `total` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('novo','preparo','entrega','finalizado','cancelado') NOT NULL DEFAULT 'novo',
  `ordered_at` DATETIME NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_orders_number` (`number`),
  KEY `idx_orders_status` (`status`),
  KEY `idx_orders_client` (`client_id`),
  CONSTRAINT `fk_orders_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` VARCHAR(64) NOT NULL,
  `product_id` VARCHAR(64) DEFAULT NULL,
  `product_name` VARCHAR(190) NOT NULL,
  `flavor` VARCHAR(190) DEFAULT NULL,
  `qty` INT NOT NULL DEFAULT 1,
  `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `idx_oi_order` (`order_id`),
  CONSTRAINT `fk_oi_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `finance` (
  `id` VARCHAR(64) NOT NULL,
  `type` ENUM('entrada','saida') NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `entry_date` DATE NOT NULL,
  `order_id` VARCHAR(64) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_finance_date` (`entry_date`),
  KEY `idx_finance_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `coupons` (
  `id` VARCHAR(64) NOT NULL,
  `code` VARCHAR(40) NOT NULL,
  `type` ENUM('percent','fixed') NOT NULL DEFAULT 'percent',
  `value` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `min_order` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  `label` VARCHAR(120) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_coupons_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `reviews` (
  `id` VARCHAR(64) NOT NULL,
  `author` VARCHAR(120) NOT NULL,
  `text` TEXT NOT NULL,
  `rating` TINYINT UNSIGNED DEFAULT 5,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `faq` (
  `id` VARCHAR(64) NOT NULL,
  `question` VARCHAR(255) NOT NULL,
  `answer` TEXT NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ---------- DADOS INICIAIS (Verônica) ----------
-- Admin: admin@veronica.com / veronica123  (troque depois no painel)
INSERT INTO `admins` (`email`, `password_hash`) VALUES (
  'admin@veronica.com',
  'veronica123'
);

INSERT INTO `settings` (
  `id`, `name`, `tagline`, `logo`, `banner`, `sobre_image`, `whatsapp`,
  `instagram`, `instagram_user`, `facebook`, `email`, `address`, `hours`,
  `followers`, `posts`, `map_embed`, `hero_badge`, `hero_story`,
  `sobre_text1`, `sobre_text2`, `delivery_fee`, `delivery_note`, `data_version`
) VALUES (
  1,
  'Ateliê Verônica Rodrigues',
  'Bolos e doces personalizados',
  'products/logo-pink.png',
  'products/foto-hero-redvelvet.jpg',
  'products/foto-veronica-historia.jpg',
  '5537998741557',
  'https://www.instagram.com/veronicabolospiumhi',
  '@veronicabolospiumhi',
  '',
  '',
  'Rua Padre Francisco Goulart, 610 — Bairro Novo Horizonte 2',
  'Pedidos pelo WhatsApp',
  '',
  '',
  '',
  'Ateliê de bolos e doces personalizados',
  '[]',
  'Meu nome é Verônica Rodrigues e o Ateliê nasceu em 2021, em meio à pandemia, quando uma oportunidade para complementar a renda se transformou na maior paixão da minha vida. Em pouco tempo, descobri que a confeitaria era o meu propósito e decidi investir em conhecimento para oferecer sempre o melhor aos meus clientes.',
  'Cada desafio que enfrentei me tornou mais forte e reforçou a certeza de que os sonhos se constroem com dedicação, amor e perseverança. Hoje, cada bolo, fatia e doce que preparo é feito com carinho, como se fosse para a minha própria família. Meu maior desejo é que cada cliente se sinta abraçado, amado e lembrado em um dos momentos mais especiais da vida. Seja bem-vindo ao Ateliê Verônica Rodrigues, onde cada receita é feita para adoçar a sua história.',
  5.00,
  'Bairros mais afastados: consultar',
  17
);

INSERT INTO `categories` (`id`, `name`, `slug`, `sort_order`) VALUES
  ('cat-bolos', 'Bolos', 'bolos', 0),
  ('cat-copos', 'Copos da Felicidade', 'copos', 1),
  ('cat-fatias', 'Fatias', 'fatias', 2);

INSERT INTO `products` (
  `id`, `name`, `description`, `price`, `price_from`, `category_id`, `image`,
  `featured`, `slug`, `size`, `promo_active`, `promo_price`, `promo_label`,
  `best_seller`, `active`, `sort_order`
) VALUES
('p-ninho-nutella', 'Bolo de Ninho com Nutella', 'Bolo de leite ninho com recheio generoso de Nutella.', 25.00, 0,
  'cat-bolos', 'products/bolo-baunilha.png', 1, 'bolo-ninho-com-nutella', '', 0, NULL, '', 1, 1, 0),

('p-ninho-morango', 'Bolo Ninho, Morango e Suspiro', 'Bolo de leite ninho com morango fresco e suspiro crocante.', 25.00, 0,
  'cat-bolos', 'products/foto-bolo-morango.jpg', 1, 'bolo-ninho-morango-suspiro', '', 0, NULL, '', 1, 1, 1),

('p-ferrero', 'Bolo Ferrero Rocher', 'Bolo Ferrero Rocher — chocolate, avelã e crocante.', 25.00, 0,
  'cat-bolos', 'products/foto-bolo-kinder.jpg', 1, 'bolo-ferrero-rocher', '', 0, NULL, '', 1, 1, 2),

('p-limao-siciliano', 'Bolo Limão Siciliano com Frutas Vermelhas', 'Bolo de limão siciliano com frutas vermelhas.', 25.00, 0,
  'cat-bolos', 'products/bolo-limao.png', 1, 'bolo-limao-siciliano-frutas-vermelhas', '', 0, NULL, '', 1, 1, 3),

('p-copo-maracuja', 'Copo da Felicidade — Maracujá Trufado com Musse de Chocolate', 'Copo da felicidade com brigadeiro de maracujá trufado e musse de chocolate.', 18.00, 0,
  'cat-copos', 'products/bolo-brownie-drip.png', 1, 'copo-felicidade-maracuja-musse-chocolate', '', 0, NULL, '', 1, 1, 4),

('p-copo-pudim', 'Copo da Felicidade — Pudim', 'Copo da felicidade com pudim cremoso de caramelo.', 22.00, 0,
  'cat-copos', 'products/pote-pudim.png', 1, 'copo-felicidade-pudim', '', 0, NULL, '', 1, 1, 5),

('p-fatia-chocobrownie', 'Fatia de Chocobrownie', 'Fatia de chocobrownie — chocolate intenso e textura fudgy.', 25.00, 0,
  'cat-fatias', 'products/foto-chocobrownie.jpg', 1, 'fatia-chocobrownie', 'fatia', 0, NULL, '', 1, 1, 6),

('p-fatia-brigadeiro-maracuja', 'Fatia de Brigadeiro com Maracujá Trufado', 'Fatia de brigadeiro com maracujá trufado.', 25.00, 0,
  'cat-fatias', 'products/foto-bolo-maracuja.jpg', 1, 'fatia-brigadeiro-maracuja-trufado', 'fatia', 0, NULL, '', 0, 1, 7),

('p-fatia-palha', 'Fatia de Palha Italiana', 'Fatia de palha italiana clássica.', 25.00, 0,
  'cat-fatias', 'products/bolo-chocolate.png', 1, 'fatia-palha-italiana', 'fatia', 0, NULL, '', 0, 1, 8),

('p-fatia-oreo', 'Fatia de Oreo', 'Fatia de Oreo — cookies & cream.', 25.00, 0,
  'cat-fatias', 'products/bolo-oreo.png', 1, 'fatia-oreo', 'fatia', 0, NULL, '', 1, 1, 9),

('p-fatia-matilda', 'Fatia Matilda', 'Fatia Matilda — chocolate cremoso e marcante.', 25.00, 0,
  'cat-fatias', 'products/bolo-chocolate-camadas.png', 1, 'fatia-matilda', 'fatia', 0, NULL, '', 1, 1, 10),

('p-fatia-ouro-branco', 'Fatia de Ouro Branco', 'Fatia de Ouro Branco — chocolate branco cremoso.', 25.00, 0,
  'cat-fatias', 'products/foto-bolo-ninho.jpg', 1, 'fatia-ouro-branco', 'fatia', 0, NULL, '', 0, 1, 11);

INSERT INTO `gallery` (`image`, `sort_order`, `active`) VALUES
  ('products/foto-veronica-vitrine.jpg', 0, 1),
  ('products/foto-hero-redvelvet.jpg', 1, 1),
  ('products/foto-bolo-kinder.jpg', 2, 1),
  ('products/foto-bolo-morango.jpg', 3, 1),
  ('products/foto-bolo-ninho.jpg', 4, 1),
  ('products/foto-chocobrownie.jpg', 5, 1),
  ('products/foto-bolo-pudim.jpg', 6, 1),
  ('products/foto-bolo-maracuja.jpg', 7, 1),
  ('products/foto-bolo-chocolate-nuts.jpg', 8, 1),
  ('products/foto-veronica-feira.jpg', 9, 1);

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

-- Fim
