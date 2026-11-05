# Eu Moro Aqui — protótipo das fases 1 e 2

Protótipo jogável das duas primeiras fases do GDD: alimentar Tob de maneira
responsável e brincar com ele, oferecendo companhia.

O histórico das decisões, o fluxo de trabalho e o padrão para novas fases e
integração de assets estão em [Processo e padrão de desenvolvimento](docs/DESENVOLVIMENTO.md).

## Como jogar

F5 inicia a campanha: conclua a fase 1 e escolha **Próxima fase** para entrar na
cutscene da fase 2. O afeto é preservado durante a sessão. Na conclusão da fase 2,
**Reiniciar jogo** retorna à primeira introdução e zera o afeto acumulado.

- `WASD` ou setas: mover a criança.
- `E` ou clique: interagir / avançar diálogos.
- `R`: reiniciar a fase depois de concluí-la.

Na campanha, o botão de conclusão e `R` seguem a ação exibida (próxima fase ou
reiniciar jogo). Executando uma fase isoladamente com F6, ambos reiniciam essa fase.

### Fase 2 — Brinque com Tob

- Fale com Tob e escolha uma ação usando o mouse ou a navegação de foco do teclado.
- **Bater o pé:** alerta sonoro e explicação em vermelho, sem pontuar ou encerrar a fase.
- **Graveto:** entre na casa e interaja com **Jogar graveto pela janela**. A animação
  provisória conclui a solução de 1 coração.
- **Brincar junto:** escolha **Correr e fazer carinho**, percorra os pontos 1, 2 e 3
  da praça com Tob acompanhando você e depois aproxime-se dele e interaja para
  fazer carinho. Essa solução rende 2 corações.
- A praça também pode ser acessada pelo marcador **Ir à praça** na rua. Sair e
  retornar à praça preserva o percurso. Fazer carinho antes de terminá-lo não pontua.

As quatro falas da introdução são as fornecidas pelo usuário/GDD, sem revisão
gramatical. A imagem é a mesma da fase 1. Praça, janela, graveto e alerta sonoro
são provisórios; carinho e lambeijos são representados pelo resultado narrativo,
sem animação específica nesta versão. Tob acompanha o jogador com seu visual atual.

Os visuais provisórios agora são nodes de cena editáveis no Godot. A casa e a rua são cenas independentes, conectadas por portas com fade. Os itens permanecem com o jogador durante as transições.

A fase começa com uma cutscene de Visual Novel: ilustração estática em tela cheia, nome de quem fala e diálogo na parte inferior. `Espaço`, `Enter`, `E`, clique no fundo ou botão avançam uma fala por vez. Ao terminar, o botão **Começar fase** inicia um fade para a gameplay; personagem, ambientes e HUD ficam ocultos e desativados até esse momento. Reiniciar a fase reapresenta a cutscene.

## Organização e edição no Godot

- `features/campaign/campaign.tscn`: cena principal, sequência das fases e afeto da sessão.
- `features/phase_one/phase_one.tscn`: composição da primeira fase, executável com F6.
- `features/phase_two/phase_two.tscn`: composição da segunda fase, também executável com F6.
- `features/phase_two/phase_two.gd`: escolhas, percurso, carinho e pontuação da fase 2.
- `features/phase_two/intro_cutscene.tres`: as quatro falas da segunda introdução.
- `features/phase_two/intro_preview.tscn`: preview da segunda introdução com F6.
- `features/phase_two/phase_content.tres`: feedback educativo e resultados da brincadeira.
- `features/phase_two/street.tscn`, `house.tscn`, `plaza.tscn`: ambientes da fase 2; rua e casa reutilizam as cenas da fase 1.
- `features/phase_one/phase_one.gd`: progresso, regras das escolhas e pontuação; não desenha o cenário ou a interface.
- `features/phase_one/phase_content.tres`: falas e explicações educativas editáveis no Inspector.
- `features/phase_one/intro_cutscene.tres`: título, ilustração e falas da introdução de Tob.
- `features/cutscene/cutscene.tscn`: apresentação reutilizável de Visual Novel, sem dependências de gameplay.
- `features/cutscene/cutscene_data.gd` e `cutscene_line.gd`: Resources para dados de qualquer cutscene/fase.
- `features/environments/street.tscn` e `house.tscn`: ambientes com cenário, marcador de entrada (`Spawn`) e objetos (`Interactions`).
- `features/player/player.tscn`: personagem, colisão, visual e componente de input.
- `features/tob/tob.tscn`: Tob reutilizável, com interação e visual em pixel art; instanciado em `street.tscn`.
- `features/tob/tob_idle.tres`: animação de espera com oito frames da folha `Dogs-Remastered-12.png`.
- `features/interaction/interactable.tscn`: objeto reutilizável com identificador, título e distância de interação exportados.
- `features/ui/phase_ui.tscn`: HUD e diálogos com Label, Button e containers nativos.
- `features/ui/phase_theme.tres`: aparência compartilhada da interface.
- `features/ui/transition.tscn`: fade independente.

Abra a cena principal no editor e dê dois cliques nas instâncias para editar suas cenas de origem. Você pode mover objetos em `Interactions`, alterar seus títulos e raio no Inspector, ajustar o marcador `Spawn` e modificar os polígonos do cenário. O controlador lê as posições dos nodes; não é preciso editar coordenadas no código. Cada subcena pode ser executada isoladamente com F6 para inspeção; o fluxo completo é executado com F5.

O controlador da fase possui o inventário e o progresso. O personagem envia pedidos de interação por signal, a UI envia pedidos para avançar, e a transição informa quando a tela está coberta. As subcenas não acessam o controlador ou autoloads.

A UI também oferece `configure_phase()`, `update_overview()` e `show_choices()`.
As escolhas emitem `choice_selected(id)`; a UI não decide o resultado. O componente
`features/tob/follow_component.gd` recebe ator e alvo, sem conhecer as regras da fase.

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

`godot --headless --path . --script tests/tob_smoke.gd`

`godot --headless --path . --script tests/phase_two_smoke.gd`

`godot --headless --path . --script tests/campaign_smoke.gd`

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
