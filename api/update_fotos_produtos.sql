-- Corrige fotos dos produtos (nome = foto certa)
UPDATE products SET image = 'products/bolo-baunilha.png' WHERE id = 'p-ninho-nutella';
UPDATE products SET image = 'products/foto-bolo-morango.jpg' WHERE id = 'p-ninho-morango';
UPDATE products SET image = 'products/foto-bolo-chocolate-nuts.jpg' WHERE id = 'p-ferrero';
UPDATE products SET image = 'products/bolo-limao.png' WHERE id = 'p-limao-siciliano';
UPDATE products SET image = 'products/bolo-brownie-drip.png' WHERE id = 'p-copo-maracuja';
UPDATE products SET image = 'products/pote-pudim.png' WHERE id = 'p-copo-pudim';
UPDATE products SET image = 'products/foto-chocobrownie.jpg' WHERE id = 'p-fatia-chocobrownie';
UPDATE products SET image = 'products/foto-bolo-maracuja.jpg' WHERE id = 'p-fatia-brigadeiro-maracuja';
UPDATE products SET image = 'products/bolo-chocolate.png' WHERE id = 'p-fatia-palha';
UPDATE products SET image = 'products/bolo-oreo.png' WHERE id = 'p-fatia-oreo';
UPDATE products SET image = 'products/bolo-chocolate-camadas.png' WHERE id = 'p-fatia-matilda';
UPDATE products SET image = 'products/foto-bolo-ninho.jpg' WHERE id = 'p-fatia-ouro-branco';

UPDATE settings SET data_version = 13 WHERE id = 1;
