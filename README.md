# Eu Moro Aqui — protótipo da Fase 1

Protótipo jogável da primeira fase do GDD: alimentar Tob de maneira responsável.

O histórico das decisões, o fluxo de trabalho e o padrão para novas fases e
integração de assets estão em [Processo e padrão de desenvolvimento](docs/DESENVOLVIMENTO.md).

## Como jogar

- `WASD` ou setas: mover a criança.
- `E` ou clique: interagir / avançar diálogos.
- `R`: reiniciar a fase depois de concluí-la.

Os visuais provisórios agora são nodes de cena editáveis no Godot. A casa e a rua são cenas independentes, conectadas por portas com fade. Os itens permanecem com o jogador durante as transições.

A fase começa com uma cutscene de Visual Novel: ilustração estática em tela cheia, nome de quem fala e diálogo na parte inferior. `Espaço`, `Enter`, `E`, clique no fundo ou botão avançam uma fala por vez. Ao terminar, o botão **Começar fase** inicia um fade para a gameplay; personagem, ambientes e HUD ficam ocultos e desativados até esse momento. Reiniciar a fase reapresenta a cutscene.

## Organização e edição no Godot

- `features/phase_one/phase_one.tscn`: cena principal que reúne os componentes.
- `features/phase_one/phase_one.gd`: progresso, regras das escolhas e pontuação; não desenha o cenário ou a interface.
- `features/phase_one/phase_content.tres`: falas e explicações educativas editáveis no Inspector.
- `features/phase_one/intro_cutscene.tres`: título, ilustração e falas da introdução de Tob.
- `features/cutscene/cutscene.tscn`: apresentação reutilizável de Visual Novel, sem dependências de gameplay.
- `features/cutscene/cutscene_data.gd` e `cutscene_line.gd`: Resources para dados de qualquer cutscene/fase.
- `features/environments/street.tscn` e `house.tscn`: ambientes com cenário, marcador de entrada (`Spawn`) e objetos (`Interactions`).
- `features/player/player.tscn`: personagem, colisão, visual e componente de input.
- `features/interaction/interactable.tscn`: objeto reutilizável com identificador, título e distância de interação exportados.
- `features/ui/phase_ui.tscn`: HUD e diálogos com Label, Button e containers nativos.
- `features/ui/phase_theme.tres`: aparência compartilhada da interface.
- `features/ui/transition.tscn`: fade independente.

Abra a cena principal no editor e dê dois cliques nas instâncias para editar suas cenas de origem. Você pode mover objetos em `Interactions`, alterar seus títulos e raio no Inspector, ajustar o marcador `Spawn` e modificar os polígonos do cenário. O controlador lê as posições dos nodes; não é preciso editar coordenadas no código. Cada subcena pode ser executada isoladamente com F6 para inspeção; o fluxo completo é executado com F5.

O controlador da fase possui o inventário e o progresso. O personagem envia pedidos de interação por signal, a UI envia pedidos para avançar, e a transição informa quando a tela está coberta. As subcenas não acessam o controlador ou autoloads.

Na rua, `Scenery/Facade` e `Scenery/Roof` possuem filhos `Body/Collision` (`StaticBody2D` + `CollisionPolygon2D`) com os mesmos contornos dos visuais. Ao editar esses polígonos, ajuste também seus contornos de colisão. O ambiente inativo fica fora da simulação física para não bloquear o jogador no outro cenário.

## Reutilizar a cutscene em outras fases

Crie um Resource `EMACutsceneData` no editor e configure `title`, `background` (Texture2D, aceita PNG/JPG/SVG) e `lines`. Cada entrada é um Resource `EMACutsceneLine` com `speaker`, `text` e uma imagem opcional que troca o fundo a partir daquela fala. O conteúdo é independente da fase 1; não armazena inventário nem pontuação.

Instancie `cutscene.tscn`, chame `play(dados)` e conecte o signal `finished` ao controlador da fase. O controlador bloqueia/oculta a gameplay e inicia a transição; chame `dismiss()` quando o fade cobrir a tela, depois habilite a gameplay ao final do fade. A imagem permanece na tela após a última fala para não revelar o cenário antes da transição. Para pré-visualizar com F6, atribua o Resource a `preview_data` no Inspector da cena de cutscene.

Para ver somente a introdução de Tob com F6, abra `features/phase_one/intro_preview.tscn`. Essa cena usa o mesmo componente e Resource do jogo, sem carregar a fase.

A arte atual (`features/cutscene/art/tob_street.svg`) é uma ilustração vetorial provisória. Para substituí-la, altere `background` em `intro_cutscene.tres`; não é necessário mudar scripts ou os visuais da rua jogável.

## Verificação

`godot --headless --path . --script tests/phase_one_smoke.gd`

`godot --headless --path . --script tests/cutscene_smoke.gd`

`godot --headless --path . --script tests/ui_feedback_smoke.gd`

O teste verifica as colisões da fachada e do telhado, a desativação da física do ambiente oculto, portas e escolhas, preservação do inventário, recompensas de 1/2 corações, reinício e carregamento independente das subcenas.

Os testes também verificam separação cutscene/gameplay, bloqueio da movimentação, sequência das falas, fade e replay, além de reutilização com outros personagens, troca de ilustração, avanço por teclado/clique e proteção contra avanço duplo.

## Objetivo pedagógico

O jogador pode testar uma escolha inadequada (restos de comida humana), receber explicação sem punição e continuar. Então escolhe entre levar só ração (+1 coração) ou ração e água fresca (+2 corações), a solução ideal do GDD.

As mensagens de escolhas corretas e conclusão usam caixa verde; restos de comida
e tentativa de alimentar sem ração usam caixa vermelha. A cor complementa o
texto educativo. Os estilos `SuccessMessage` e `ErrorMessage` são editáveis em
`phase_theme.tres`, sem alterar o HUD ou a cutscene. `show_message()` aceita
`EMAPhaseUI.Feedback.NEUTRAL`, `SUCCESS` ou `ERROR` no quarto argumento;
mensagens sem classificação preservam o estilo original.
