# Configurar imagens das cutscenes no Godot

O mesmo motor suporta várias imagens ao longo da narrativa e várias imagens
simultâneas: um fundo e uma lista de camadas transparentes desenhadas sobre ele.
Não é necessário juntar os PNGs num editor de imagens ou alterar scripts para
configurar uma nova composição.

## Dados da cutscene

Abra `features/phase_one/intro_cutscene.tres` ou
`features/phase_two/intro_cutscene.tres` no Inspector:

- **Finish Button Text:** rótulo do último avanço; padrão “Começar fase”.
  Use “Ver resultado” em epílogos, como nos encerramentos da fase 5.
- **Background:** imagem inicial do cenário.
- **Overlays:** imagens transparentes iniciais, em ordem de desenho. A primeira
  fica atrás das seguintes. Pode haver quantas camadas forem necessárias à cena.
- **Lines:** lista das falas; abra cada entrada para configurar o trecho.

Em cada `EMACutsceneLine`:

- **Speaker / Text:** personagem que fala e texto, como antes.
- **Background:** se preenchido, troca o fundo nessa fala; vazio mantém o anterior.
- **Overlays:** uma lista preenchida substitui todas as camadas anteriores.
  Uma lista vazia mantém as camadas que já estavam visíveis.
- **Clear Overlays:** marcado, remove as camadas anteriores. Use com a lista vazia
  para mostrar somente o cenário; com uma lista preenchida, mostra a nova lista.

Exemplo: na fala sobre a infância, escolha `floresta.png` em Background e adicione
`tob_filhote.png` e `mae_tob.png` em Overlays. Na próxima fala, selecione
`riacho.png` em Background e deixe Overlays vazio para manter os dois personagens.
Para voltar ao presente, escolha `poste.png` e uma nova lista com `tob_triste.png`.

## Enquadramento e compatibilidade

Fundo e camadas preenchem a tela inteira, mantendo a proporção, com o título e
o diálogo por cima. O mesmo enquadramento (`Keep Aspect Covered`) é aplicado a
todas as imagens para preservar seu alinhamento. O filtro nearest preserva
o pixel art. Para sprites com posição
pré-definida, usar PNGs transparentes com as mesmas dimensões do cenário — as
artes da equipe já usam canvas de 1024 × 512. Margens transparentes fazem parte
do alinhamento. Imagens com proporções diferentes serão centralizadas de forma
independente; prepare o canvas comum se precisar de alinhamento exato.

O viewport do jogo é 1024 × 512, assim como o canvas das artes da equipe: nessa
resolução, as imagens ocupam a tela inteira sem recortes. Imagens de outra proporção
podem ter as bordas recortadas para preencher o viewport sem deformação. A caixa
de diálogo cobre intencionalmente a parte inferior da arte; margens e fontes
permanecem adequadas à resolução-base.

A composição final continua visível após a última fala até o fade da fase chamar
`dismiss()`. O replay reaplica as imagens iniciais, sem manter camadas da execução
anterior. Cutscenes antigas que só definem Background continuam funcionando.

Nesta versão as trocas ocorrem ao avançar as falas, sem crossfade entre imagens
ou animação dos sprites. Os controles e o fade entre cutscene e gameplay não mudam.

## Pré-visualização e testes

- Fase 1: abrir `features/phase_one/intro_preview.tscn` e executar F6.
- Fase 2: abrir `features/phase_two/intro_preview.tscn` e executar F6.
- Para outros dados: instanciar `cutscene.tscn` e configurar `preview_data`.
- Teste específico: `godot --headless --path . --script tests/cutscene_artwork_smoke.gd`.

As camadas são geradas em `Overlays` a partir dos Resources. A configuração
autoral deve ser feita nas listas de imagens do Inspector, não nos nós temporários
da árvore Remote durante a execução.
