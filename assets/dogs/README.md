# Pixel Dogs-Sprites — Tob

`Dogs-Remastered-12.png` foi copiado sem alterações do pack fornecido pelo usuário
em `/home/fbrandes/Documentos/Assets/Pixel Dogs-Sprites/` (obtido no itch.io).
Autoria e licença ainda precisam ser confirmadas antes de distribuir o jogo;
nenhum arquivo de licença foi encontrado na pasta consultada.

A folha tem 512 × 432 pixels, com células de 64 × 48. A primeira linha (oito
células) foi recortada como animação em pé, `idle`, em
`features/tob/tob_idle.tres`. As outras poses permanecem na imagem original,
disponíveis para futuras animações; não foram associadas a regras de outras fases.

`features/tob/tob.tscn` contém o AnimatedSprite2D com filtro nearest, escala
inteira 2 × e reprodução em loop a 6 FPS. Os frames são AtlasTextures editáveis
no Inspector, sem exportar imagens recortadas ou alterar a folha original.
