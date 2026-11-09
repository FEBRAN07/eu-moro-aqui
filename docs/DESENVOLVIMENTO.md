# Processo e padrão de desenvolvimento — Eu Moro Aqui

Este documento registra o trabalho realizado no protótipo das fases 1 a 5 e define
um fluxo para as próximas alterações. Descreve o estado atual do projeto;
recomendações futuras não significam funcionalidades já implementadas.

## 1. Partir do GDD e delimitar a entrega

O desenvolvimento começou pela leitura do GDD fornecido pelo usuário em
`~/Downloads/GDDfinal.pdf`. O conceito foi traduzido em um recorte jogável:
uma criança ajuda Tob, um cachorro de rua, aprendendo sobre cuidado responsável.

Para implementar a terceira fase, foi consultada a cópia atualizada em
`/home/fbrandes/Documentos/extensao/GDDfinal.pdf`, incluindo as quatro falas e as
três soluções de abrigo, sem revisão do conteúdo original da cutscene.
A primeira entrega ficou limitada à fase de alimentação, não ao jogo completo.

As regras implementadas nesse recorte são:

- Restos de comida humana geram orientação educativa, sem alimento ou afeto.
- Água sozinha não conclui a fase.
- Ração adequada rende um coração; ração e água fresca rendem dois.
- A ida e volta entre casa e rua preserva os itens coletados.
- Reiniciar limpa o progresso e reapresenta a introdução.

**Padrão:** antes de implementar, registrar objetivo pedagógico, ações do jogador,
condições de conclusão, feedback e o que fica fora da entrega. O GDD orienta o
conceito; as solicitações posteriores do usuário orientam os ajustes do protótipo.

## 2. Evolução do protótipo até aqui

1. **Validar o núcleo jogável:** movimento, interação, falas, escolhas e afeto.
   A versão inicial concentrava lógica e desenho em um script; foi uma etapa de
   prototipação, não o padrão arquitetural adotado depois.
2. **Separar ambientes:** rua e interior da casa passaram a ter transição por
   porta e fade, preservando o inventário.
3. **Separar responsabilidades:** os ambientes, jogador, objetos interativos,
   HUD, transição e conteúdo foram extraídos para cenas, scripts e Resources.
   Os visuais passaram a ser nós nativos editáveis no editor, sem `_draw()`.
4. **Corrigir a entrada:** os códigos físicos das setas esquerda/direita no
   InputMap estavam incorretos. A correção foi validada com as constantes do
   próprio Godot; WASD e as quatro setas passaram a ter mapeamentos corretos.
5. **Adicionar colisões da casa:** `Facade` e `Roof` receberam corpos estáticos
   e polígonos de colisão. A porta continuou acessível; a física da rua foi
   desativada quando o jogador está no interior.
6. **Separar narrativa de gameplay:** a introdução virou uma cutscene de Visual
   Novel com fundo estático e diálogo inferior. O jogador e o HUD ficam ocultos
   durante a narrativa, e um fade marca o início da gameplay.
7. **Integrar assets fornecidos:** os potes da spritesheet `FreeDemo.png` foram
   associados às interações de ração e água, sem mudar as regras de coleta.

O trabalho evoluiu em alterações pequenas, seguidas por verificações de
carregamento e testes de comportamento. Ajustes feitos pelo usuário no editor
devem ser preservados em alterações seguintes.

## 3. Organização e propriedade das responsabilidades

Organizar por funcionalidade, não por uma pasta global de todos os scripts ou
de todas as cenas. Manter nomes de arquivos em `snake_case` e nomes de nós
descritivos. As classes próprias existentes usam o prefixo `EMA`.

| Local | Responsabilidade | Não deve assumir |
| --- | --- | --- |
| `features/phase_one/` | Compor a fase e controlar estado, inventário, escolhas e afeto | Desenhar o cenário ou controlar o movimento |
| `features/environments/` | Cenário, colisões, spawn, limites e objetos locais | Progresso e recompensa da fase |
| `features/player/` | Input, movimento, colisão e aviso de interação | Regras de alimentação ou acesso ao HUD |
| `features/interaction/` | Identificador, título, proximidade e disponibilidade do objeto | Decidir a recompensa de uma escolha |
| `features/cutscene/` | Apresentar uma sequência narrativa independente | Conhecer inventário ou iniciar uma fase específica |
| `features/ui/` | Exibir status, mensagens e fade | Decidir progresso ou pontuação |
| `assets/` | Assets importados e recortes reutilizáveis | Regras de gameplay |
| `tests/` | Verificar comportamento e regressões | Substituir uma avaliação visual do jogo |

### Contratos entre componentes

- O personagem emite `interaction_requested`; o controlador consulta o ambiente
  e decide a ação. Identificadores existentes: `door`, `leftovers`, `food`,
  `water` e `tob`.
- O HUD emite `advance_requested`; o controlador decide como continuar o feedback.
- A cutscene recebe `EMACutsceneData` por `play()` e emite `finished` uma vez.
  O controlador decide o próximo passo e chama `dismiss()` sob o fade.
- A transição emite `covered` para permitir a troca de conteúdo e `finished`
  para liberar novamente os controles.
- O controlador emite `affection_changed` e `phase_completed`; eles estão
  disponíveis para futuros consumidores, sem exigir um autoload global.

**Padrão:** o componente filho informa acontecimentos por signal; o controlador
chama seus métodos públicos. Evitar caminhos absolutos na árvore ou acesso do
filho ao controlador. Usar `%UniqueName` para referências internas estáveis e
propriedades exportadas para configurações editáveis.

Os dados autorais ficam em Resources `.tres`; o estado da partida fica no
controlador ou componente responsável. Não gravar o inventário nos Resources
de conteúdo nem alterar um Resource compartilhado para representar progresso.

### Feedback visual das escolhas

O controlador classifica a mensagem usando `EMAPhaseUI.Feedback`: `SUCCESS`
para ração, água e conclusão; `ERROR` para restos de comida e tentativa de
alimentar sem ração; `NEUTRAL` para mensagens sem julgamento. A UI aplica
as variações `SuccessMessage` (verde) e `ErrorMessage` (vermelha), definidas
em `phase_theme.tres`, somente ao painel de diálogo. Não modificar o StyleBox
compartilhado em runtime: isso mudaria também HUD, botões e cutscene.
Ao ocultar a mensagem ou abrir uma neutra, a UI restaura o estilo original.
A cor é complementar; manter o texto explicativo para não depender só dela.

## 4. Ciclo recomendado para cada alteração

1. **Inspecionar:** ler os arquivos envolvidos e verificar alterações existentes
   do usuário. Identificar o responsável pelo comportamento a modificar.
2. **Definir o resultado:** transformar o pedido em critérios observáveis e
   registrar qualquer suposição importante.
3. **Implementar no menor escopo coerente:** editar a cena para composição e
   aparência; o Resource para conteúdo; o script proprietário para comportamento.
   Criar um componente novo quando houver responsabilidade própria ou reutilização
   concreta, não uma abstração para cada pequena mudança.
4. **Importar e carregar:** deixar o Godot importar assets e registrar classes.
   Verificar erros de sintaxe, referências ausentes e falhas de instanciação.
5. **Testar comportamento:** ampliar o teste pertinente para a alteração e
   executar também os testes de regressão relacionados.
6. **Inspecionar no editor/jogo:** usar F6 para subcenas e F5 para o fluxo completo.
   Se o ambiente não permitir isso, registrar a validação visual como pendente.
7. **Documentar e entregar:** explicar o resultado, onde editar, o que foi testado
   e quaisquer limitações. Atualizar este padrão quando surgir uma decisão nova.

Ao trabalhar por arquivos, usar patches pequenos e revisar o resultado. Ao
trabalhar pelo editor, salvar as cenas e revisar o que mudou. Não sobrescrever
uma cena inteira para uma mudança pontual nem desfazer ajustes não relacionados.

## 5. Padrão de cenas, movimento e ambientes

### Resolução-base: 1024 × 512

Viewport e tamanho inicial da janela agora usam 1024 × 512, conforme solicitado
pela equipe de arte. O override antigo de 1152 × 648 também foi atualizado.
O HUD tem largura de 224 pixels, margens compactas e quebra de linha nos textos.
O painel de feedback usa âncoras inferiores e reserva espaço para o HUD, sem
depender de coordenadas fixas como o antigo limite inferior de 622 pixels.
As cutscenes têm painel e fontes compactos, com arte em tela cheia e diálogo sobreposto.

Coordenadas de tela e de mundo são conceitos separados. Os mapas provisórios
continuam com uma área de referência de 890 × 648; `world_camera.tscn` calcula
zoom uniforme para enquadrá-la na área disponível, com origem visível em (0, 0).
Isso preserva colisões, velocidade em unidades de mundo e posições de interações,
portas e percurso. Não diminuir manualmente todas as coordenadas ou escalar os
corpos físicos para acompanhar uma mudança da janela. Os limites inferiores de
movimento foram ajustados para manter também os rótulos dentro do enquadramento.

As câmeras `standalone_world_camera.tscn` dos ambientes só ficam ativas quando o
ambiente é executado como cena isolada. Dentro de uma fase, ficam desativadas
para não competir com sua câmera. CanvasLayers da UI e da cutscene não recebem
o zoom do mundo. Os fundos provisórios foram estendidos para preencher a largura
visível, sem modificar os desenhos e colisões da casa ou as imagens importadas.

Os testes de mouse/layout usam a resolução-base atual, não a janela antiga.
`resolution_smoke.gd` verifica os retângulos dos painéis e botões, textos longos,
espaço para a arte, pontos de interação em coordenadas de tela e limites de movimento.

- Cenas reutilizáveis devem carregar isoladamente com F6, sem depender de uma
  fase específica. Sem dados de preview, é aceitável que uma cutscene não apareça.
- Movimento usa ações do InputMap, não testes diretos de teclas no controlador.
  `player_input.gd` interpreta entrada; `player.gd` movimenta o `CharacterBody2D`
  em `_physics_process()` usando `move_and_slide()`.
- As ações existentes são `move_left`, `move_right`, `move_up`, `move_down`,
  `interact`, `advance` e `restart`. Testar bindings físicos além de testar ações:
  `Input.action_press()` sozinho não detecta um código de tecla incorreto.
- Ambientes expõem `Spawn`, `walk_bounds` e `Interactions`. O controlador deve
  usar `set_active()` para trocar ambientes: ocultar um cenário sozinho não
  remove suas colisões do mundo físico.
- Obstáculos sólidos usam `StaticBody2D` com `CollisionShape2D` ou
  `CollisionPolygon2D`, não apenas `Polygon2D` ou uma área de interação.
- Ao editar contornos de `Facade`/`Roof`, atualizar também `Body/Collision`;
  a igualdade dos contornos não é sincronizada automaticamente.
- Ajustar dimensões da forma de colisão, evitando escalar o nó de colisão.
  Verificar máscaras/camadas, spawn fora de obstáculos e acesso às portas.

## 6. Padrão de narrativa e novas fases

### Composição visual por fala

O motor de cutscene foi ampliado para compor um cenário com várias camadas PNG
transparentes. `EMACutsceneData.background` e `overlays` definem o estado inicial;
os mesmos campos em `EMACutsceneLine` permitem trocar as imagens por fala. Uma
lista de overlays não vazia substitui as anteriores; vazia preserva as existentes,
exceto quando `clear_overlays` estiver marcado. O replay restaura os valores
iniciais e o apresentador nunca altera os Resources autorais.

Fundos e camadas usam o mesmo enquadramento proporcional em tela cheia, com a
caixa de diálogo sobreposta e filtro nearest. As artes fornecidas em `~/Imagens/Sprites EMA` têm canvas
comum de 1024 × 512 e foram copiadas sem recortes para `assets/team/cutscenes/`.
Somente imagens necessárias às introduções implementadas foram importadas; o sprite de
Tob na gameplay e os textos das falas não foram alterados. A composição usa
frames estáticos, sem introduzir animação ou transição temporizada entre imagens.
Configuração no Inspector: [guia das cutscenes](../features/cutscene/README.md).

O fluxo da fase 1, executada isoladamente, é:

```text
INTRO → STARTING_GAMEPLAY (fade) → EXPLORE ⇄ FEEDBACK → COMPLETE
  ↑                                                     |
  └──────────────── reiniciar ──────────────────────────┘
```

Durante a introdução, gameplay e HUD ficam ocultos e os controles bloqueados.
Na última fala, a cutscene permanece visível enquanto o fade fecha a tela.
Em `covered`, o controlador substitui a cutscene pelo cenário. Apenas após
`finished` a movimentação é liberada. Durante as portas, o mesmo fade troca
somente o ambiente, sem limpar o inventário.

### Preparar conteúdo de outra fase

1. Criar uma pasta de funcionalidade para a fase e uma cena que componha os
   componentes existentes necessários.
2. Criar um `EMACutsceneData` com título, fundo e lista de `EMACutsceneLine`.
   Cada entrada possui personagem, texto e imagem opcional para trocar o fundo.
3. Instanciar `cutscene.tscn`, chamar `play(dados)` e conectar `finished` ao
   fluxo da fase. Reutilizar a apresentação; não duplicar seu código.
4. Definir as regras próprias da fase em seu controlador/conteúdo e configurar
   ambientes, itens, objetivo e critérios de conclusão.
5. Criar testes para caminhos ideais, escolhas alternativas, transições e reset.

Para visualizar a introdução atual isoladamente, abrir
`features/phase_one/intro_preview.tscn` e executar F6. Para outra introdução,
atribuir seus dados a `preview_data` de uma instância de cutscene.

### Fase 2 e sequência da campanha

`features/campaign/campaign.tscn` agora é a cena principal (F5). Seu controlador
mantém a sequência das cinco fases e o afeto acumulado durante a sessão, sem
autoload. As cenas das fases continuam independentes para F6; na campanha,
`continue_on_complete` e `completion_button_text` configuram a ação de conclusão.
`next_phase_requested` solicita a troca. A transição da campanha usa layer 30,
acima dos fades internos das fases, e bloqueia input enquanto troca instâncias.
O afeto é registrado no signal de conclusão, sem acumular mensagens repetidas.

Na fase 2, o controlador mantém estados exclusivos para introdução, transição,
exploração, escolha, feedback, brincadeira, arremesso e conclusão. A cutscene tem
as quatro falas exatamente como solicitadas, inclusive as expressões gramaticais
do texto original, e usa a mesma biblioteca de artes da equipe da fase 1. O Resource
`features/phase_two/phase_content.tres` contém o feedback e os resultados.

- Bater o pé: menu ao interagir com Tob, alerta sonoro provisório e orientação
  literal do GDD; não encerra a fase nem concede afeto.
- Graveto: entrar na casa, interagir com a janela e aguardar a animação simples
  do arremesso; concede um coração.
- Companhia: correr pela praça com Tob, visitar três marcadores em ordem e
  depois fazer carinho; concede dois corações. O resultado narrativo representa
  também os lambeijos e o tempo juntos, sem animação específica de carinho.

A praça é uma cena separada, com percurso editável em `Route/Point1..Point3`.
O componente opcional `EMAFollowComponent` move um ator em direção a um alvo
configurado, sem acessar progresso, UI ou controlador. O progresso do percurso
permanece ao sair/voltar à praça e não é atualizado durante diálogos ou fades.
Visuais da praça/janela/graveto e o áudio são placeholders.

Rua e casa da fase 2 reutilizam as cenas existentes por herança de cena, sem
copiar todo o cenário. Itens de alimentação estão ocultos e não interagem nessa
fase. `EMAEnvironment.target_at()` ignora objetos ocultos e escolhe o mais próximo
entre os disponíveis, para Tob não encobrir interações como a saída da praça.

O HUD oferece `configure_phase()` e `update_overview()` para conteúdo de outras
fases, além de `show_choices()` com até três botões editáveis na cena. As escolhas
emitem `choice_selected(id)`; o controlador decide o efeito. Avançar uma mensagem
não pula um menu de escolhas. Fala educativa e classificação de cores permanecem
independentes do widget que as apresenta.

### Fase 3 — Abrigo durante a tempestade

A terceira fase reutiliza jogador, Tob, UI, câmera, cutscene em tela cheia,
transição e som de alerta. Rua e casa são cenas herdadas com mudanças locais;
itens de alimentação permanecem ocultos. Os materiais `cloth` e `kennel` são
coletados na casa e preservados pelo controlador ao atravessar portas.

O menu de Tob oferece pano ao relento, casinha ou abrigo dentro de casa.
Colocar um pano produz o alerta e o texto literal do GDD, sem premiar ou impedir
nova tentativa. Montar a casinha exige ter coletado o item e concede um coração.
Convidar Tob ativa o componente de acompanhamento após o diálogo, sem recompensa
imediata. Ao interagir com a porta, a transição move a apresentação do Tob para
o interior; só ao terminar o fade são concedidos dois corações. Os dois finais
mostram feedback verde e bloqueiam recompensas repetidas.

`phase_three.gd` possui o inventário de abrigo e os estados de introdução,
transição, exploração, escolha, feedback e conclusão. `phase_content.tres`
contém mensagens; `intro_cutscene.tres` contém as quatro falas exatas do GDD.
O cenário da cutscene vem de `posteChuvoso.png`, copiado sem alterações. O pano,
a casinha e a chuva da gameplay são recursos provisórios nativos: polígonos,
uma cena reutilizável de casinha e `CPUParticles2D`, sem alterar colisões herdadas.

Na campanha, a fase 2 avança para a fase 3 e esta para a fase 4; o reinício completo
fica na conclusão da quinta. O HUD suporta até dez corações, com fonte menor
quando necessário para caber nos 224 pixels da lateral. As cinco fases ainda
reiniciam isoladamente quando executadas com F6. O reset da terceira limpa
materiais, pano colocado, casinha, acompanhamento e posição/visibilidade dos
dois Tobs (exterior e interior), e reapresenta a introdução.

### Fase 4 — Adulto e atendimento veterinário

As três falas da introdução foram transcritas do GDD, com o personagem suspeitando
de doença, sem a apresentação confirmar um diagnóstico. O cuidado é representado
por água, conversa com a mãe, orientação profissional e consulta na clínica.
O pote de água reutiliza o asset existente; a mãe e o veterinário reutilizam
uma cena interativa de adulto, com visual provisório diferente por instância.
O uivo de entrada é sintetizado e substituível por um áudio no Inspector.

Apenas água produz orientação vermelha e alerta, sem concluir a fase. O caminho
de um coração exige que o jogador fale com a mãe, peça orientação veterinária
e volte a Tob; o adulto, e não a criança, fica responsável pelo cuidado prescrito.
O caminho de dois corações exige combinar a ida com um adulto, viajar até uma
clínica separada e interagir com o veterinário. A chegada não premia sozinha.
O estado de cuidado é preservado ao atravessar portas e ao sair/voltar da clínica.
Reset restaura água, disponibilidade de coleta, flags de orientação e companhia,
visuais e o uivo de entrada, além de reapresentar a cutscene.

**Decisão de segurança documentada:** a descrição do GDD sobre dipirona foi
adaptada para não ensinar que ela é sempre segura, nem simular dose ou escolha
de medicamento pela criança. A medicação só é mencionada como cuidado prescrito,
sob responsabilidade de um adulto com orientação veterinária. A pontuação de
um/dois corações foi mantida. Esta é uma alteração deliberada do conteúdo educativo,
não uma transcrição literal das soluções. Referência: [FDA — perguntas sobre
medicamentos para animais](https://www.fda.gov/animal-veterinary/safety-health/frequently-asked-questions-about-animal-drugs).
O objetivo é reforçar ajuda profissional; revisão do conteúdo por um veterinário
antes da aplicação educativa continua recomendada.

As cenas da fase 4 ficam em `features/phase_four/`. O controlador possui escolhas,
água e pré-requisitos, sem delegar diagnóstico à UI. As falas e os feedbacks ficam
em Resources. `assets/team/cutscenes/characters/tob_doente.png` e a imagem da
clínica foram copiados das artes da equipe sem alterações. As outras fases não
foram reescritas para incluir regras médicas; a campanha apenas ganhou uma entrada.

### Fase 5 — Acolhimento, adoção e encerramento

A última fase segue o GDD atualizado em `/home/fbrandes/Documentos/extensao/GDDfinal.pdf`:
a introdução contém apenas “...”, com Tob deitado e triste. O jogador inicia a
interação, sem adicionar falas ao cachorro. Ignorar e voltar para dentro de casa
produz o alerta literal do GDD; não conclui nem concede afeto.

A caminha com mantas exige coleta na casa e rende um coração. A adoção exige
recolher Tob na rua, entrar em casa com ele e conversar com a mãe para pedir
“Mãe, deixa o Tob morar conosco”. Só então o caminho de dois corações é validado.
Tob carregado acompanha visualmente a criança e é substituído pela instância
interna ao atravessar a porta. A mãe reutiliza `adult.tscn`; a caminha é uma
subcena nativa provisória. A pose deitado usa um recorte da spritesheet existente.

O controlador `features/phase_five/phase_five.gd` possui os pré-requisitos e um
estado `ENDING`. O fade oculta a gameplay, apresenta uma cutscene de epílogo e
retorna ao resumo; a recompensa é emitida uma única vez, ao mostrar o resultado.
Input permanece bloqueado durante transições. Os epílogos acrescentam narração
para apresentar os resultados descritos no GDD; não são transcrições de falas
originais. Os dois finais são alternativas, sem exigir pontuação mínima anterior.

O motor de cutscenes ganhou `finish_button_text`, mantendo “Começar fase” como
padrão e usando “Ver resultado” nos epílogos. Cenários e personagens continuam
Resources separados, com arte da equipe preservada. A campanha percorre as cinco
fases, acumula até dez corações e reinicia na fase 1 ao terminar. Executar a fase
isoladamente reinicia somente ela. O reset limpa coleta, acolhimento, adoção,
visibilidade dos Tobs e caminha, e reapresenta a introdução.

**Limite atual:** não há salvamento
persistente, inventário genérico ou controlador universal. As fases compartilham
componentes concretos; suas regras e parte do ciclo de vida permanecem em
controladores próprios. Algumas falas e posições iniciais ainda estão em scripts.

## 7. Padrão de integração de assets

1. Localizar o arquivo real, inclusive possíveis subpastas do pack.
2. Inspecionar a spritesheet e identificar visualmente o elemento desejado.
3. Copiar o original para o projeto, sem depender de caminhos em Downloads ou
   Documentos durante a execução. Não modificar o pack de origem.
4. Para spritesheets, criar recortes `AtlasTexture` `.tres` com região explícita.
   Evitar gerar uma cópia PNG de cada sprite quando um recorte resolve.
5. Aplicar a textura a um nó visual editável. Usar filtro nearest para pixel art;
   preferir escala inteira quando o tamanho desejado permitir.
6. Substituir apenas a apresentação necessária, preservando posição, título,
   `action_id`, raio e regras de interação.
7. Testar a importação e o comportamento depois da troca. Revisar transparência,
   recorte, proporções e alinhamento no editor.
8. Registrar origem e licença. Se os termos não estiverem disponíveis, deixar
   isso explícito e verificá-los antes da distribuição; “Free” no nome não basta.

### Exemplo realizado: potes

O original do pack PetMobileFree foi copiado para `assets/pets/FreeDemo.png`.
`food_bowl.tres` recorta `(112, 40, 48, 40)`; `water_bowl.tres` recorta
`(40, 184, 20, 20)`. O pote de água usa um pote azul vazio da folha, sem desenho
adicional de água. Esses Resources são exibidos por `Sprite2D` em
`Interactions/Food/Bowl` e `Interactions/Water/Bowl` dentro de `house.tscn`.

Os nós provisórios `Outline`, `Token` e `Icon` foram ocultados apenas nesses
dois objetos. O título, o indicador e o feedback da coleta foram preservados.
O arquivo [README dos assets](../assets/pets/README.md) registra os detalhes.

### Aplicação realizada: restos de comida

O arquivo individual `27. Cooked beef.png` do pack Food icons foi copiado sem
modificações para `assets/food/cooked_beef.png`. Por já ser uma imagem isolada
de 32 × 32 pixels, foi aplicada diretamente a `Interactions/Leftovers/FoodSprite`,
sem AtlasTexture, com escala inteira 2 × e filtro nearest. Os visuais provisórios
foram ocultados, preservando `action_id = &"leftovers"`, posição, título, indicador
e orientação educativa, sem conceder ração ou afeto.
Detalhes de origem e licença pendente estão no [README do asset](../assets/food/README.md).

### Tob como cena reutilizável

`features/tob/tob.tscn` especializa a cena de interação existente e reúne o
visual, o título, o indicador e o identificador `tob`. A rua instancia essa
cena em `Interactions/Tob`, mantendo a posição e o contrato de proximidade.
As regras de alimentação e afeto continuam no controlador da fase; Tob não
conhece o HUD ou os dados da fase 1.

A spritesheet fornecida `Dogs-Remastered-12.png` foi copiada para `assets/dogs/`.
O Resource `tob_idle.tres` recorta a primeira linha em oito células de 64 × 48;
um `AnimatedSprite2D` reproduz a sequência em pé a 6 FPS com escala 2 × e
filtro nearest. Não foram introduzidos movimento, IA ou novas regras.

Nas próximas fases, instanciar `tob.tscn` sob `Interactions` do ambiente para
reutilizar a descoberta por proximidade. Alterar a aparência na cena de Tob e
as animações no SpriteFrames, sem duplicar seu visual dentro de cada cenário.
Abrir `tob.tscn` com F6 permite inspecionar a animação sem carregar uma fase.
A arte das cutscenes é independente e não foi substituída por esta alteração.
Origem e licença pendente estão no [README dos cachorros](../assets/dogs/README.md).

## 8. Ferramentas e limites de verificação

A skill `godot-master` foi utilizada como referência para arquitetura,
composição de cenas, UI, física e práticas de desenvolvimento. Seu uso não
significa executar o servidor MCP.

O MCP do Godot foi testado anteriormente: consulta de informações do projeto e
abertura do editor funcionaram. As tentativas de executar o jogo por ele não
mantiveram um processo ativo. Nas alterações recentes, os arquivos foram
editados diretamente e o Godot foi executado pelo terminal para importar e
testar; o MCP não foi utilizado nessas implementações.

**Padrão:** usar editor, MCP ou terminal conforme a operação e a disponibilidade.
Sempre distinguir pedido de abertura, importação, teste headless e inspeção visual.
Um retorno de “lançado” não comprova que a janela continuou aberta nem que o
comportamento foi observado.

A versão observada durante os testes foi Godot `4.7.2`. Na sessão de trabalho,
o editor headless apresentou erros de criação de sockets por restrições do
ambiente; a execução gráfica não conseguiu conectar a X11/Wayland. Isso foi
separado dos resultados de carregamento e dos testes de gameplay. Falhas novas
não devem ser descartadas automaticamente como restrições do ambiente.

## 9. Validação e critérios de entrega

Executar a partir da raiz do projeto:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/phase_one_smoke.gd
godot --headless --path . --script tests/cutscene_smoke.gd
godot --headless --path . --script tests/cutscene_artwork_smoke.gd
godot --headless --path . --script tests/ui_feedback_smoke.gd
godot --headless --path . --script tests/tob_smoke.gd
godot --headless --path . --script tests/phase_two_smoke.gd
godot --headless --path . --script tests/phase_three_smoke.gd
godot --headless --path . --script tests/phase_four_smoke.gd
godot --headless --path . --script tests/phase_five_smoke.gd
godot --headless --path . --script tests/campaign_smoke.gd
godot --headless --path . --script tests/resolution_smoke.gd
```

Quando a sessão não permitir escrita nos diretórios pessoais do Godot, prefixar
cada comando com:

```sh
env XDG_DATA_HOME=/tmp/eu_moro_aqui_godot_data XDG_CONFIG_HOME=/tmp/eu_moro_aqui_godot_config
```

Testes automatizados disponíveis, verificados no desenvolvimento das cinco fases:

- `phase_one_smoke.gd`: separação narrativa/gameplay, bloqueio de movimento,
  fade, colisões, ambientes inativos, importação dos potes, portas, inventário,
  escolhas, recompensas de um/dois corações, reset e carregamento de subcenas.
- `cutscene_smoke.gd`: dados de outra fase, personagens, troca de fundo,
  teclado, clique no botão/fundo, proteção contra repetição e avanço duplo,
  conclusão única, replay e preview independente.
- `cutscene_artwork_smoke.gd`: múltiplas imagens simultâneas, fundos por fala,
  ordem das camadas, preservação/remoção, replay, alinhamento da arte da equipe
  e cobertura integral da tela com diálogo desenhado acima da arte.
- `ui_feedback_smoke.gd`: resolução dos estilos verde/vermelho, retorno ao
  estilo neutro e isolamento do tema compartilhado. O teste da fase também
  verifica a classificação de cada ação integrada à gameplay.
- `tob_smoke.gd`: Tob isolado, recortes e reprodução da animação, filtro/escala,
  disponibilidade independente por instância e integração com a rua.
- `phase_two_smoke.gd`: texto exato das quatro falas, imagem compartilhada,
  bloqueio de movimento, escolhas e orientação, alerta, janela/arremesso,
  praça/percurso/companhia/carinho, saída/retorno, recompensas e reset.
- `phase_three_smoke.gd`: quatro falas exatas e arte chuvosa, bloqueio na intro,
  materiais obrigatórios, coleta/portas, alerta do pano, casinha e um coração,
  acompanhamento até dentro de casa e dois corações, seis corações no HUD,
  recompensa única, reset e cenas independentes.
- `phase_four_smoke.gd`: texto e arte da intro, uivo, água, pré-requisitos de adulto
  e orientação profissional, clínica e avaliação, recompensas únicas, reset,
  oito corações e cenas independentes.
- `phase_five_smoke.gd`: silêncio da intro, alerta ao ignorar, coleta da caminha,
  acolhimento, pré-requisitos da mãe, epílogos, recompensa única, resumo, reset
  e dez corações na resolução-base.
- `campaign_smoke.gd`: passagem pelas fases 1 a 5, proteção contra duplo avanço,
  afeto acumulado e reinício completo do jogo.
- `resolution_smoke.gd`: viewport/janela 1024 × 512, geometria do HUD e das
  mensagens/escolhas, cutscenes, enquadramento das interações, limites inferiores
  de movimento e ativação das câmeras de preview somente em cenas isoladas.

Esses testes não verificam a qualidade visual do recorte ou a composição da
tela. **A inspeção gráfica das últimas mudanças ficou pendente nesta sessão.**

Checklist manual para fechar uma entrega visual:

- [ ] F5: percorrer o fluxo completo, incluindo escolhas alternativas e reset.
- [ ] F6: abrir os componentes modificados e, para narrativa, a cena de preview.
- [ ] Testar WASD, todas as setas, teclado de diálogo e clique, sem avanço duplo.
- [ ] Verificar recortes, transparência, tamanhos, legibilidade e sobreposições.
- [ ] Conferir colisões e acesso às interações nos dois ambientes.
- [ ] Verificar que HUD e controles não aparecem/funcionam durante a cutscene.
- [ ] Conferir erros no debugger e testar o layout em tamanhos de janela diferentes.

Uma entrega deve informar testes executados e pendências separadamente.
Não declarar aprovação visual baseada somente em teste headless.

## 10. Modelo de registro para próximas tarefas

```text
Pedido / objetivo pedagógico:
Escopo e critérios de aceitação:
Arquivos e componente responsável:
Dados/Resources e assets envolvidos (origem/licença):
Decisões e suposições:
Implementação realizada:
Testes executados e resultado:
Inspeção visual executada ou pendente:
Onde editar no Godot:
Limitações e próximos passos:
```

Manter o README como entrada rápida, este documento como padrão do projeto e
os READMEs locais para detalhes de packs/funcionalidades. Atualizar esses registros
quando o processo mudar, sem transformar hipóteses futuras em estado implementado.
