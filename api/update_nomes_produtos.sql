-- Corrige nomes e fotos dos produtos (cardápio Verônica)
-- phpMyAdmin → banco u586160337_atelie_conf → SQL → Executar

UPDATE products SET
  name = 'Bolo de Ninho com Nutella',
  description = 'Bolo de leite ninho com recheio generoso de Nutella.',
  image = 'products/bolo-baunilha.png',
  slug = 'bolo-ninho-com-nutella'
WHERE id = 'p-ninho-nutella';

UPDATE products SET
  name = 'Bolo Ninho, Morango e Suspiro',
  description = 'Bolo de leite ninho com morango fresco e suspiro crocante.',
  image = 'products/foto-bolo-morango.jpg',
  slug = 'bolo-ninho-morango-suspiro'
WHERE id = 'p-ninho-morango';

UPDATE products SET
  name = 'Bolo Ferrero Rocher',
  description = 'Bolo Ferrero Rocher — chocolate, avelã e crocante.',
  image = 'products/foto-bolo-kinder.jpg',
  slug = 'bolo-ferrero-rocher'
WHERE id = 'p-ferrero';

UPDATE products SET
  name = 'Bolo Limão Siciliano com Frutas Vermelhas',
  description = 'Bolo de limão siciliano com frutas vermelhas.',
  image = 'products/bolo-limao.png',
  slug = 'bolo-limao-siciliano-frutas-vermelhas'
WHERE id = 'p-limao-siciliano';

UPDATE products SET
  name = 'Copo da Felicidade — Maracujá Trufado com Musse de Chocolate',
  description = 'Copo da felicidade com brigadeiro de maracujá trufado e musse de chocolate.',
  image = 'products/bolo-brownie-drip.png',
  slug = 'copo-felicidade-maracuja-musse-chocolate'
WHERE id = 'p-copo-maracuja';

UPDATE products SET
  name = 'Copo da Felicidade — Pudim',
  description = 'Copo da felicidade com pudim cremoso de caramelo.',
  image = 'products/pote-pudim.png',
  slug = 'copo-felicidade-pudim'
WHERE id = 'p-copo-pudim';

UPDATE products SET
  name = 'Fatia de Chocobrownie',
  description = 'Fatia de chocobrownie — chocolate intenso e textura fudgy.',
  image = 'products/foto-chocobrownie.jpg',
  slug = 'fatia-chocobrownie'
WHERE id = 'p-fatia-chocobrownie';

UPDATE products SET
  name = 'Fatia de Brigadeiro com Maracujá Trufado',
  description = 'Fatia de brigadeiro com maracujá trufado.',
  image = 'products/foto-bolo-maracuja.jpg',
  slug = 'fatia-brigadeiro-maracuja-trufado'
WHERE id = 'p-fatia-brigadeiro-maracuja';

UPDATE products SET
  name = 'Fatia de Palha Italiana',
  description = 'Fatia de palha italiana clássica.',
  image = 'products/bolo-chocolate.png',
  slug = 'fatia-palha-italiana'
WHERE id = 'p-fatia-palha';

UPDATE products SET
  name = 'Fatia de Oreo',
  description = 'Fatia de Oreo — cookies & cream.',
  image = 'products/bolo-oreo.png',
  slug = 'fatia-oreo'
WHERE id = 'p-fatia-oreo';

UPDATE products SET
  name = 'Fatia Matilda',
  description = 'Fatia Matilda — chocolate cremoso e marcante.',
  image = 'products/bolo-chocolate-camadas.png',
  slug = 'fatia-matilda'
WHERE id = 'p-fatia-matilda';

UPDATE products SET
  name = 'Fatia de Ouro Branco',
  description = 'Fatia de Ouro Branco — chocolate branco cremoso.',
  image = 'products/foto-bolo-ninho.jpg',
  slug = 'fatia-ouro-branco'
WHERE id = 'p-fatia-ouro-branco';

UPDATE settings SET data_version = 14 WHERE id = 1;
