# PetMobileFree — ícones dos potes

`FreeDemo.png` foi copiado do pack fornecido pelo usuário em
`~/Documentos/Assets/PetMobileFree/PetMobileFree/FreeDemo.png`, sem modificações.
A licença/autoria não veio acompanhada de um arquivo de texto nesta pasta;
confirme os termos do pack antes de distribuir o jogo.

Os recursos `food_bowl.tres` e `water_bowl.tres` são recortes `AtlasTexture`
editáveis no Inspector. O pote azul claro com ração fica em `(112, 40, 48, 40)`;
o pote azul vazio usado para água fica em `(40, 184, 20, 20)`.

Na cena `house.tscn`, os nós `Interactions/Food/Bowl` e
`Interactions/Water/Bowl` usam esses recursos com filtro nearest, preservando
o pixel art. Os ícones provisórios foram ocultados somente nesses dois objetos;
títulos, indicador de interação e regras de coleta permanecem iguais.
