-- Atualiza texto da história (Nossa história)
-- phpMyAdmin → u586160337_atelie_conf → SQL → Executar

UPDATE `settings`
SET
  `sobre_text1` = 'Meu nome é Verônica Rodrigues e o Ateliê nasceu em 2021, em meio à pandemia, quando uma oportunidade para complementar a renda se transformou na maior paixão da minha vida. Em pouco tempo, descobri que a confeitaria era o meu propósito e decidi investir em conhecimento para oferecer sempre o melhor aos meus clientes.',
  `sobre_text2` = 'Cada desafio que enfrentei me tornou mais forte e reforçou a certeza de que os sonhos se constroem com dedicação, amor e perseverança. Hoje, cada bolo, fatia e doce que preparo é feito com carinho, como se fosse para a minha própria família. Meu maior desejo é que cada cliente se sinta abraçado, amado e lembrado em um dos momentos mais especiais da vida. Seja bem-vindo ao Ateliê Verônica Rodrigues, onde cada receita é feita para adoçar a sua história.',
  `data_version` = 15
WHERE `id` = 1;
