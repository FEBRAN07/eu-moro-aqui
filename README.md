# Eu Moro Aqui — protótipo das fases 1 a 5

Protótipo jogável das cinco fases do GDD: alimentar Tob de maneira
responsável, brincar com ele, oferecer abrigo, procurar cuidado quando ele parece doente e ajudá-lo a ter uma família.

O histórico das decisões, o fluxo de trabalho e o padrão para novas fases e
integração de assets estão em [Processo e padrão de desenvolvimento](docs/DESENVOLVIMENTO.md).

## Resolução e enquadramento

A resolução-base e a janela inicial são **1024 × 512**. O HUD ocupa os 224 pixels
da direita; diálogos e escolhas ficam ancorados na parte inferior da área jogável.
A cutscene usa o viewport inteiro, com margens e tipografia compactas para essa
resolução, sem alterar o canvas de 1024 × 512 das artes importadas.

Os mapas provisórios mantêm suas coordenadas de mundo originais. A cena
`features/environments/world_camera.tscn` os enquadra proporcionalmente na tela,
sem escalar colisões ou mudar as distâncias das interações. Por isso, coordenadas
como `y = 570` continuam válidas no mapa, mas aparecem dentro dos 512 pixels da
tela. Os limites de movimento reservam espaço para os rótulos do jogador.

Rua, casa e praça também possuem uma câmera de preview, ativa somente quando
executadas isoladamente com F6. Nas fases, apenas a câmera principal fica ativa.

## Como jogar

F5 inicia a campanha: conclua a fase 1 e escolha **Próxima fase** para entrar na
cutscene da fase 2; ao concluir a brincadeira, avance para a fase 3. O afeto é
preservado durante a sessão. As fases seguintes levam ao encerramento na fase 5, com até dez corações
acumulados. Na conclusão da fase 5,
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
gramatical. As cutscenes usam cenários e personagens separados das artes da equipe,
com mudanças de imagens conforme as falas. Praça, janela, graveto e alerta sonoro
são provisórios; carinho e lambeijos são representados pelo resultado narrativo,
sem animação específica nesta versão. Tob acompanha o jogador com seu visual atual.

Os visuais provisórios agora são nodes de cena editáveis no Godot. A casa e a rua são cenas independentes, conectadas por portas com fade. Os itens permanecem com o jogador durante as transições.

### Fase 3 — Abrigo na tempestade

- A introdução tem as quatro falas da fase 3 do GDD em
  `/home/fbrandes/Documentos/extensao/GDDfinal.pdf`, sem alterar o texto.
- A cutscene usa o cenário `poste_chuvoso.png` da equipe, com Tob em camadas
  sobrepostas. A gameplay tem rua escurecida e chuva provisória com partículas.
- Entre na casa para pegar o pano e/ou a casinha. As interações de alimentação
  não estão disponíveis nesta fase; os itens de abrigo permanecem no inventário
  ao trocar de ambiente.
- Interaja com Tob para escolher **Pano ao relento**, **Montar casinha** ou
  **Levar para casa**. As duas primeiras opções exigem buscar o material antes.
- **Pano:** é colocado junto ao poste, mas gera alerta sonoro e orientação em
  vermelho, sem pontuar ou encerrar a fase. Você pode tentar outra solução.
- **Casinha de madeira:** é montada junto ao poste e abriga Tob; rende 1 coração.
- **Dentro de casa:** convide Tob, avance a mensagem e conduza-o até a porta.
  Interaja com a porta para entrar: após o fade, Tob aparece no interior e a fase
  termina com 2 corações. Só convidá-lo não concede recompensa.

Para testar diretamente, abra `features/phase_three/phase_three.tscn` e execute
F6; para visualizar só as falas, use `features/phase_three/intro_preview.tscn`.
Pano, casinha, chuva e alerta sonoro têm visuais/áudio provisórios, editáveis no
Godot. O Tob da gameplay continua usando sua cena reutilizável atual.

### Fase 4 — Cuide de Tob

- Cutscene com as três falas do GDD, após a tempestade, usando a arte do Tob
  doente produzida pela equipe. Ao começar a gameplay, há um uivo sintetizado provisório.
- **Água apenas:** pegue água na casa, volte a Tob e escolha essa ação. Carinho
  e água são representados pelo texto e pote, mas não encerram a fase: há alerta
  sonoro e orientação em vermelho para procurar ajuda profissional.
- **Cuidado com adulto:** fale com a mãe dentro de casa, escolha **Pedir orientação**
  e volte a Tob. A mãe recebe orientação veterinária na narrativa; só então
  **Cuidado com adulto** conclui o acompanhamento do cuidado prescrito e rende 1 coração.
- **Veterinário:** peça à mãe para ir à clínica, saia de casa e use o marcador
  **Ir à clínica com adulto**. Também é possível escolher **Buscar veterinário**
  ao falar com Tob depois de combinar a ida com a mãe. Na clínica, interaja com
  o veterinário para concluir a avaliação e receber 2 corações.
- Água e participação do adulto são preservadas nas trocas entre rua, casa e clínica.
  Chegar à clínica sem falar com o veterinário não concede recompensa.

**Adaptação educativa em relação ao GDD:** as falas da introdução foram preservadas,
mas não se apresenta dipirona como universalmente segura, nem há seleção de remédio,
dose ou administração pela criança. O caminho de 1 coração exige ajuda adulta e
orientação veterinária prévia; o caminho de 2 corações representa atendimento na clínica.
A segurança da medicação e o diagnóstico dependem de avaliação profissional, não da
suspeita do personagem. Veja [a orientação da FDA sobre medicamentos para animais](https://www.fda.gov/animal-veterinary/safety-health/frequently-asked-questions-about-animal-drugs).

Para testar só a fase, abra `features/phase_four/phase_four.tscn` e pressione F6.
Para a cutscene isolada, abra `features/phase_four/intro_preview.tscn`.
A mãe, o veterinário, a clínica da gameplay e os sons são provisórios; a arte da
clínica feita pela equipe está importada e aparece como ilustração no ambiente.

### Fase 5 — Uma família para Tob

- A introdução preserva a única fala do GDD: **“...”**. Tob está deitado,
  triste e sem responder, com arte da equipe na cutscene.
- **Carinho e ir embora:** volte para dentro da casa para receber o alerta
  educativo vermelho do GDD. Não pontua; permite tentar outra solução.
- **Levar caminha:** pegue a caminha com mantas dentro de casa e ofereça-a a Tob.
  Conclui com 1 coração e um encerramento de cuidado temporário.
- **Acolher em casa:** recolha Tob, entre pela porta com ele e converse com a mãe.
  Peça **“Mãe, deixa o Tob morar conosco”** para concluir a adoção com 2 corações.
  Só carregar Tob ou entrar em casa não concede recompensa.
- Cada solução positiva tem uma cutscene de encerramento e um resumo do afeto
  da fase e da campanha. O final de adoção mostra Tob com uma família; a caminha
  mantém explícita a necessidade de companhia. O resumo oferece **Reiniciar jogo**.

As falas adicionais do epílogo são adaptações narrativas para apresentar os
resultados do GDD; a introdução permanece silenciosa. A caminha da gameplay tem
visual provisório editável, e Tob usa uma pose deitado da spritesheet existente.
Execute `features/phase_five/phase_five.tscn` com F6 para testar só a última fase,
ou `features/phase_five/intro_preview.tscn` para ver sua introdução.

A fase começa com uma cutscene de Visual Novel: cenários e personagens preenchem a tela inteira, com o diálogo sobreposto na parte inferior. `Espaço`, `Enter`, `E`, clique no fundo ou botão avançam uma fala por vez. Ao terminar, o botão **Começar fase** inicia um fade para a gameplay; personagem, ambientes e HUD ficam ocultos e desativados até esse momento. Reiniciar a fase reapresenta a cutscene.

## Organização e edição no Godot

- `features/campaign/campaign.tscn`: cena principal, sequência das fases e afeto da sessão.
- `features/phase_one/phase_one.tscn`: composição da primeira fase, executável com F6.
- `features/phase_two/phase_two.tscn`: composição da segunda fase, também executável com F6.
- `features/phase_two/phase_two.gd`: escolhas, percurso, carinho e pontuação da fase 2.
- `features/phase_two/intro_cutscene.tres`: as quatro falas da segunda introdução.
- `features/phase_two/intro_preview.tscn`: preview da segunda introdução com F6.
- `features/phase_two/phase_content.tres`: feedback educativo e resultados da brincadeira.
- `features/phase_two/street.tscn`, `house.tscn`, `plaza.tscn`: ambientes da fase 2; rua e casa reutilizam as cenas da fase 1.
- `features/phase_three/phase_three.tscn`: composição da terceira fase, executável com F6.
- `features/phase_three/phase_three.gd`: inventário de abrigo, escolhas, acompanhamento e recompensas.
- `features/phase_three/intro_cutscene.tres` e `phase_content.tres`: falas e feedback de abrigo editáveis no Inspector.
- `features/phase_three/street.tscn`, `house.tscn`, `rain.tscn`: ambientes herdados e chuva provisória.
- `features/phase_four/phase_four.tscn`: quarta fase, independente e ligada à campanha.
- `features/phase_four/phase_four.gd` e `phase_content.tres`: regras e conteúdo educativo de cuidado.
- `features/phase_four/street.tscn`, `house.tscn`, `clinic.tscn`: rua, casa e clínica da quarta fase.
- `features/phase_five/phase_five.tscn`: última fase, executável isoladamente e integrada à campanha.
- `features/phase_five/phase_five.gd` e `phase_content.tres`: acolhimento, adoção, pré-requisitos e resultado final.
- `features/phase_five/temporary_ending.tres` e `adoption_ending.tres`: encerramentos editáveis no Inspector.
- `features/shelter/dog_bed.tscn`: caminha com mantas reutilizável.
- `features/npc/adult.tscn`: NPC provisório reutilizado pela mãe e pelo veterinário.
- `features/shelter/doghouse.tscn`: visual de casinha reutilizável na coleta e no abrigo colocado.
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

Crie um Resource `EMACutsceneData` no editor e configure `title`, `background`
(Texture2D, aceita PNG/JPG/SVG), `overlays` (camadas transparentes) e `lines`.
Cada entrada é um `EMACutsceneLine` com `speaker`, `text`, um `background` opcional
e uma lista opcional de `overlays`. Imagens omitidas mantêm a composição anterior;
`clear_overlays` permite remover personagens/camadas. O conteúdo é independente
da fase 1; não armazena inventário nem pontuação.

Veja o [guia de composição das cutscenes](features/cutscene/README.md) para
configurar várias imagens por fala no Inspector. A arte ocupa a tela inteira,
com o diálogo por cima; os PNGs da equipe mantêm seu canvas comum e alinhamento.

Instancie `cutscene.tscn`, chame `play(dados)` e conecte o signal `finished` ao controlador da fase. O controlador bloqueia/oculta a gameplay e inicia a transição; chame `dismiss()` quando o fade cobrir a tela, depois habilite a gameplay ao final do fade. A imagem permanece na tela após a última fala para não revelar o cenário antes da transição. Para pré-visualizar com F6, atribua o Resource a `preview_data` no Inspector da cena de cutscene.

Para ver somente a introdução de Tob com F6, abra `features/phase_one/intro_preview.tscn`. Essa cena usa o mesmo componente e Resource do jogo, sem carregar a fase.

As artes usadas nas introduções estão em `assets/team/cutscenes/`, com
[registro de origem](assets/team/cutscenes/README.md). Os Resources de cada fase
escolhem fundos e personagens por fala; as falas existentes foram preservadas.
Essa mudança não substitui os visuais da rua ou o sprite de Tob na gameplay.

## Verificação

`godot --headless --path . --script tests/phase_one_smoke.gd`

`godot --headless --path . --script tests/cutscene_smoke.gd`

`godot --headless --path . --script tests/cutscene_artwork_smoke.gd`

`godot --headless --path . --script tests/ui_feedback_smoke.gd`

`godot --headless --path . --script tests/tob_smoke.gd`

`godot --headless --path . --script tests/phase_two_smoke.gd`

`godot --headless --path . --script tests/phase_three_smoke.gd`

`godot --headless --path . --script tests/phase_four_smoke.gd`

`godot --headless --path . --script tests/phase_five_smoke.gd`

`godot --headless --path . --script tests/campaign_smoke.gd`

`godot --headless --path . --script tests/resolution_smoke.gd`

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
